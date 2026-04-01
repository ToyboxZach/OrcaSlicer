#ifndef slic3r_WipeTowerEstimation_hpp_
#define slic3r_WipeTowerEstimation_hpp_

#include <algorithm>
#include <cmath>
#include <functional>
#include <vector>

#include "Config.hpp"
#include "libslic3r.h"

namespace Slic3r::WipeTowerEstimation {

struct Inputs
{
    float x { 0.0f };
    float y { 0.0f };
    float width { 0.0f };
    float volume { 0.0f };
    float tower_brim_width { 0.0f };
    bool  enable_wrapping { false };
};

inline Inputs resolve_inputs(const DynamicPrintConfig& config, int plate_index)
{
    Inputs in;

    if (const auto* opt = dynamic_cast<const ConfigOptionFloats*>(config.option("wipe_tower_x")))
        in.x = opt->get_at(plate_index);
    if (const auto* opt = dynamic_cast<const ConfigOptionFloats*>(config.option("wipe_tower_y")))
        in.y = opt->get_at(plate_index);
    if (const auto* opt = dynamic_cast<const ConfigOptionFloat*>(config.option("prime_tower_width")))
        in.width = opt->value;
    if (const auto* opt = dynamic_cast<const ConfigOptionFloat*>(config.option("prime_volume")))
        in.volume = opt->value;
    if (const auto* opt = dynamic_cast<const ConfigOptionFloat*>(config.option("prime_tower_brim_width")))
        in.tower_brim_width = opt->value;
    if (const auto* opt = dynamic_cast<const ConfigOptionBool*>(config.option("enable_wrapping_detection")))
        in.enable_wrapping = opt->value;

    return in;
}

template <typename Objects, typename IncludeFn, typename HeightFn>
inline double objects_max_height(const Objects& objects, IncludeFn include_object, HeightFn object_height)
{
    double max_height = 0.0;
    for (size_t i = 0; i < objects.size(); ++i) {
        const auto* obj = objects[i];
        if (!obj || !include_object(i, *obj))
            continue;

        max_height = std::max(max_height, object_height(*obj));
    }
    return max_height;
}

inline double filament_change_volume(const DynamicPrintConfig& config)
{
    std::vector<double> change_lengths;
    if (const auto* lengths_opt = config.option<ConfigOptionFloats>("filament_change_length"))
        change_lengths = lengths_opt->values;

    const double length = change_lengths.empty() ? 0.0 : *std::max_element(change_lengths.begin(), change_lengths.end());

    std::vector<double> diameters;
    if (const auto* diameters_opt = config.option<ConfigOptionFloats>("filament_diameter"))
        diameters = diameters_opt->values;

    const double diameter = diameters.empty() ? 1.75 : *std::max_element(diameters.begin(), diameters.end());
    return length * PI * diameter * diameter / 4.0;
}

inline Vec3d estimate_size(const DynamicPrintConfig& config,
                           double                    width,
                           double                    wipe_volume,
                           int                       extruder_count,
                           int                       plate_extruder_size,
                           bool                      need_wipe_tower,
                           bool                      use_rib_wall,
                           double                    rib_width,
                           double                    max_height,
                           double                    filament_change_volume,
                           double                    extra_rib_length,
                           const std::function<float(float)>& min_depth_for_height)
{
    Vec3d wipe_tower_size = Vec3d::Zero();
    wipe_tower_size(2)    = max_height;

    if (plate_extruder_size <= 0)
        return wipe_tower_size;

    double layer_height = 0.08;
    if (const ConfigOption* layer_height_opt = config.option("layer_height"))
        layer_height = layer_height_opt->getFloat();

    double extra_spacing = 1.0;
    if (const ConfigOption* spacing_opt = config.option("prime_tower_infill_gap"))
        extra_spacing = spacing_opt->getFloat() / 100.0;

    double volume = wipe_volume * (extruder_count == 2 ? plate_extruder_size : (plate_extruder_size - 1));
    if (extruder_count == 2)
        volume += filament_change_volume * static_cast<int>(plate_extruder_size / 2);

    if (use_rib_wall) {
        double depth = std::sqrt(volume / layer_height * extra_spacing);
        if (need_wipe_tower || plate_extruder_size > 1) {
            const float min_depth    = min_depth_for_height(static_cast<float>(max_height));
            const double volume_depth = depth;
            depth                    = std::max(static_cast<double>(min_depth), depth);
            rib_width                = std::min(rib_width, depth / 2.0);
            depth                    = rib_width / std::sqrt(2.0) + std::max(depth + extra_rib_length, volume_depth);
            wipe_tower_size(0)       = depth;
            wipe_tower_size(1)       = depth;
        }
    } else {
        double depth = 0.0;
        if (layer_height > 0.0 && width > 0.0)
            depth = volume / (layer_height * width) * extra_spacing;

        if (need_wipe_tower || depth > EPSILON) {
            const float min_depth = min_depth_for_height(static_cast<float>(max_height));
            depth = std::max(static_cast<double>(min_depth), depth);
        }

        wipe_tower_size(0) = width;
        wipe_tower_size(1) = depth;
    }

    return wipe_tower_size;
}

inline float resolved_brim_width(const DynamicPrintConfig& config,
                                 float                     tower_height,
                                 const std::function<float(float)>& auto_brim_for_height)
{
    const ConfigOption* brim_opt = config.option("prime_tower_brim_width");
    if (!brim_opt)
        return 0.0f;

    float brim_width = brim_opt->getFloat();
    if (brim_width < 0.0f)
        brim_width = auto_brim_for_height(tower_height);
    return brim_width;
}

inline void clamp_position(float& x,
                           float& y,
                           int    plate_width,
                           int    plate_depth,
                           float  tower_width,
                           float  tower_depth,
                           float  tower_brim_width,
                           float  brim_width)
{
    const float margin = static_cast<float>(WIPE_TOWER_MARGIN) + tower_brim_width;
    const float max_x  = std::max(margin, static_cast<float>(plate_width) - tower_width - margin - brim_width);
    const float max_y  = std::max(margin, static_cast<float>(plate_depth) - tower_depth - margin - brim_width);
    x                  = std::clamp(x, margin, max_x);
    y                  = std::clamp(y, margin, max_y);
}

} // namespace Slic3r::WipeTowerEstimation

#endif // slic3r_WipeTowerEstimation_hpp_
