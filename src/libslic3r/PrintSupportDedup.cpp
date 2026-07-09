#include "Print.hpp"

#include "BoundingBox.hpp"
#include "ClipperUtils.hpp"
#include "ExtrusionEntity.hpp"
#include "ExtrusionEntityCollection.hpp"
#include "Layer.hpp"

#include <cmath>
#include <memory>
#include <utility>
#include <vector>

#include <boost/format.hpp>
#include <boost/log/trivial.hpp>

namespace Slic3r {
namespace {

struct ClaimedSupportLayer
{
    coordf_t   print_z { 0. };
    ExPolygons islands;
    BoundingBox bbox;
};

struct SupportClipMask
{
    ExPolygons               expolygons;
    std::vector<BoundingBox> bboxes;
    BoundingBox              bbox;

    bool empty() const { return expolygons.empty(); }
};

static void translate_expolygons(ExPolygons &expolygons, const Point &shift)
{
    for (ExPolygon &expolygon : expolygons)
        expolygon.translate(shift);
}

static BoundingBox bbox_from_points(const Points &points)
{
    BoundingBox bbox;
    for (const Point &point : points)
        bbox.merge(point);
    if (bbox.defined)
        bbox.offset(SCALED_EPSILON);
    return bbox;
}

static BoundingBox bbox_from_entity(const ExtrusionEntity &entity)
{
    Points points;
    entity.collect_points(points);
    return bbox_from_points(points);
}

static BoundingBox bbox_from_support_layer(const SupportLayer &support_layer)
{
    if (!support_layer.support_islands.empty())
        return get_extents(support_layer.support_islands).inflated(SCALED_EPSILON);
    return bbox_from_entity(support_layer.support_fills);
}

static bool entity_may_overlap_bbox(const ExtrusionEntity &entity, const BoundingBox &bbox)
{
    if (!bbox.defined)
        return true;
    const BoundingBox entity_bbox = bbox_from_entity(entity);
    return entity_bbox.defined && entity_bbox.overlap(bbox);
}

static SupportClipMask make_support_clip_mask(ExPolygons &&expolygons)
{
    SupportClipMask mask;
    mask.expolygons = std::move(expolygons);
    mask.bboxes.reserve(mask.expolygons.size());
    for (const ExPolygon &expolygon : mask.expolygons) {
        BoundingBox bbox = get_extents(expolygon).inflated(SCALED_EPSILON);
        mask.bboxes.emplace_back(bbox);
        if (bbox.defined)
            mask.bbox.merge(bbox);
    }
    return mask;
}

static ExPolygons expolygons_overlapping_bbox(const SupportClipMask &clip_mask, const BoundingBox &bbox)
{
    if (!bbox.defined)
        return clip_mask.expolygons;

    ExPolygons out;
    for (size_t i = 0; i < clip_mask.expolygons.size(); ++i) {
        const BoundingBox &expolygon_bbox = clip_mask.bboxes[i];
        if (expolygon_bbox.defined && expolygon_bbox.overlap(bbox))
            out.emplace_back(clip_mask.expolygons[i]);
    }
    return out;
}

static ExPolygons support_layer_claim_islands(const SupportLayer &support_layer)
{
    if (!support_layer.support_islands.empty())
        return support_layer.support_islands;

    if (support_layer.support_fills.empty())
        return {};

    Polygons covered;
    support_layer.support_fills.polygons_covered_by_spacing(covered, float(SCALED_EPSILON));
    return covered.empty() ? ExPolygons() : union_ex(covered);
}

static void append_claimed_support_layer(
    std::vector<ClaimedSupportLayer> &claimed_layers,
    const PrintObject                &object,
    const SupportLayer               &support_layer)
{
    ExPolygons local_islands = support_layer_claim_islands(support_layer);
    if (local_islands.empty())
        return;

    if (object.instances().empty()) {
        BoundingBox bbox = get_extents(local_islands);
        if (bbox.defined)
            claimed_layers.push_back({ support_layer.print_z, std::move(local_islands), bbox });
        return;
    }

    for (const PrintInstance &instance : object.instances()) {
        ExPolygons world_islands = local_islands;
        translate_expolygons(world_islands, instance.shift);
        BoundingBox bbox = get_extents(world_islands);
        if (bbox.defined)
            claimed_layers.push_back({ support_layer.print_z, std::move(world_islands), bbox });
    }
}

static void append_clipped_support_entity(
    const ExtrusionEntity       &entity,
    const SupportClipMask       &clip_mask,
    ExtrusionEntityCollection   &dst)
{
    if (clip_mask.empty() || !entity_may_overlap_bbox(entity, clip_mask.bbox)) {
        dst.entities.emplace_back(entity.clone());
        return;
    }

    if (const ExtrusionPath *path = dynamic_cast<const ExtrusionPath*>(&entity)) {
        if (!path->empty()) {
            const BoundingBox path_bbox = bbox_from_entity(*path);
            ExPolygons path_clip_mask = expolygons_overlapping_bbox(clip_mask, path_bbox);
            if (path_clip_mask.empty())
                dst.entities.emplace_back(path->clone());
            else
                path->subtract_expolygons(path_clip_mask, &dst);
        }
        return;
    }

    if (const ExtrusionMultiPath *multipath = dynamic_cast<const ExtrusionMultiPath*>(&entity)) {
        for (const ExtrusionPath &path : multipath->paths)
            append_clipped_support_entity(path, clip_mask, dst);
        return;
    }

    if (const ExtrusionLoop *loop = dynamic_cast<const ExtrusionLoop*>(&entity)) {
        for (const ExtrusionPath &path : loop->paths)
            append_clipped_support_entity(path, clip_mask, dst);
        return;
    }

    if (const ExtrusionEntityCollection *collection = dynamic_cast<const ExtrusionEntityCollection*>(&entity)) {
        std::unique_ptr<ExtrusionEntityCollection> clipped_collection = std::make_unique<ExtrusionEntityCollection>();
        clipped_collection->no_sort = collection->no_sort;
        for (const ExtrusionEntity *child : collection->entities)
            append_clipped_support_entity(*child, clip_mask, *clipped_collection);
        if (!clipped_collection->empty())
            dst.entities.emplace_back(clipped_collection.release());
        return;
    }

    dst.entities.emplace_back(entity.clone());
}

static bool clip_support_layer_by_mask(SupportLayer &support_layer, const SupportClipMask &clip_mask)
{
    if (clip_mask.empty() || support_layer.support_fills.empty() || !entity_may_overlap_bbox(support_layer.support_fills, clip_mask.bbox))
        return false;

    ExtrusionEntityCollection clipped_fills;
    clipped_fills.no_sort = support_layer.support_fills.no_sort;
    for (const ExtrusionEntity *entity : support_layer.support_fills.entities)
        append_clipped_support_entity(*entity, clip_mask, clipped_fills);
    support_layer.support_fills.swap(clipped_fills);

    // Keep support_islands aligned with the printable support footprint. This is cheaper and safer than rebuilding extrusion
    // paths from polygons, and it lets later objects claim only what still prints. If support_islands were absent, callers
    // fall back to polygons_covered_by_spacing() after clipping when creating subsequent claims.
    if (!support_layer.support_islands.empty())
        support_layer.support_islands = diff_ex(support_layer.support_islands, clip_mask.expolygons);

    // Tree support brims and first-layer hull logic may use SupportLayer::lslices instead of support_fills, so trim them too.
    // This is still cheaper than regenerating tree support because it only touches layers whose support paths actually overlapped.
    if (!support_layer.lslices.empty()) {
        support_layer.lslices = diff_ex(support_layer.lslices, clip_mask.expolygons);
        support_layer.lslices_bboxes.clear();
        support_layer.lslices_bboxes.reserve(support_layer.lslices.size());
        for (const ExPolygon &expolygon : support_layer.lslices)
            support_layer.lslices_bboxes.emplace_back(get_extents(expolygon));
    }

    return true;
}

static ExPolygons support_overlap_mask_for_layer(
    const std::vector<ClaimedSupportLayer> &claimed_layers,
    const PrintObject                      &object,
    const SupportLayer                     &support_layer,
    const BoundingBox                      &support_layer_bbox)
{
    ExPolygons clip_mask;

    for (const ClaimedSupportLayer &claimed_layer : claimed_layers) {
        if (std::abs(claimed_layer.print_z - support_layer.print_z) >= EPSILON)
            continue;

        if (object.instances().empty()) {
            if (support_layer_bbox.defined && claimed_layer.bbox.defined && !support_layer_bbox.overlap(claimed_layer.bbox))
                continue;
            expolygons_append(clip_mask, claimed_layer.islands);
            continue;
        }

        for (const PrintInstance &instance : object.instances()) {
            BoundingBox claimed_bbox_local = claimed_layer.bbox;
            if (claimed_bbox_local.defined)
                claimed_bbox_local.translate(-instance.shift);
            if (support_layer_bbox.defined && claimed_bbox_local.defined && !support_layer_bbox.overlap(claimed_bbox_local))
                continue;

            const size_t dst_idx = clip_mask.size();
            expolygons_append(clip_mask, claimed_layer.islands);
            for (size_t i = dst_idx; i < clip_mask.size(); ++i)
                clip_mask[i].translate(-instance.shift);
        }
    }

    // Do not eagerly union every claim: keeping raw expolygons avoids an additional large boolean operation in wasm.
    // Later helpers precompute mask bboxes and pass each path only the overlapping mask islands before calling diff_pl().
    return clip_mask;
}

} // namespace

void Print::deduplicate_support_layers()
{
    if (m_config.print_sequence == PrintSequence::ByObject || m_objects.size() <= 1)
        return;

    // First-claim-wins support overlap removal. We walk objects in print order, claim each already-clipped support island in
    // world coordinates, then clip later objects' support paths at the same print_z against those claims translated back to
    // the later object's local coordinates.
    // This intentionally clips ExtrusionPath geometry instead of rebuilding support_fills from coverage polygons: path roles,
    // flow, width, height, no_sort grouping and generated support patterns are preserved, which avoids the wasm out-of-bounds
    // crash caused by creating invalid loops from filled-area polygons.
    // Performance: bbox filtering keeps the common no-overlap case cheap. Extra memory is proportional to the claimed support
    // islands already processed, not all pairwise support_fills coverage polygons. Worst case remains O(objects * layers *
    // overlapping island complexity), which is expected only when many objects share the same XY support footprint.
    std::vector<ClaimedSupportLayer> claimed_layers;
    size_t                           clipped_layers = 0;

    for (PrintObject *object : m_objects) {
        if (object->support_layers().empty())
            continue;

        for (SupportLayer *support_layer : object->support_layers()) {
            if (support_layer == nullptr || support_layer->support_fills.empty())
                continue;

            const BoundingBox support_layer_bbox = bbox_from_support_layer(*support_layer);
            SupportClipMask clip_mask = make_support_clip_mask(
                support_overlap_mask_for_layer(claimed_layers, *object, *support_layer, support_layer_bbox));
            if (clip_mask.empty())
                continue;

            if (clip_support_layer_by_mask(*support_layer, clip_mask))
                ++clipped_layers;
        }

        for (const SupportLayer *support_layer : object->support_layers())
            if (support_layer != nullptr && !support_layer->support_fills.empty())
                append_claimed_support_layer(claimed_layers, *object, *support_layer);
    }

    if (clipped_layers > 0)
        BOOST_LOG_TRIVIAL(debug) << boost::format("Deduplicated overlapping support paths on %1% support layers") % clipped_layers;
}

} // namespace Slic3r
