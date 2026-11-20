//TB PRINT_FIXES
#include "TBFixes.hpp"

#include "libslic3r/Exception.hpp"
#include "libslic3r/Layer.hpp"
#include "libslic3r/Model.hpp"
#include "libslic3r/ObjectID.hpp"
#include "libslic3r/Point.hpp"
#include "libslic3r/Print.hpp"
#include "libslic3r/PrintConfig.hpp"
#include "libslic3r/libslic3r.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <functional>
#include <iostream>
#include <map>
#include <string>
#include <vector>

#include <boost/format.hpp>
#include <boost/log/trivial.hpp>
#include <boost/nowide/iostream.hpp>

namespace Slic3r {
namespace TBFixes {

static bool lower_empty_first_layers(Print &print, Model &model, const std::vector<size_t> &object_ids,
                                     std::map<size_t, double> &lowered,
                                     const std::function<void(const std::string &, size_t, double)> &record_adjustment)
{
    struct Adjustment {
        ModelObject *object;
        size_t instance;
        double distance;
    };
    constexpr double limit = 200.;
    std::vector<Adjustment> adjustments;
    const double z_scale = print.shrinkage_compensation().z();
    if (!std::isfinite(z_scale) || z_scale <= 0.)
        return false;

    for (size_t object_id : object_ids) {
        const PrintObject *object = nullptr;
        for (const PrintObject *candidate : print.objects())
            if (candidate->id().id == object_id) {
                object = candidate;
                break;
            }
        if (object == nullptr || object->layers().empty() || object->layers().front()->has_extrusions())
            return false;

        const double first_z = object->layers().front()->slice_z;
        const auto next = std::find_if(object->layers().begin(), object->layers().end(), [first_z](const Layer *layer) {
            return layer->slice_z > first_z + EPSILON && layer->has_extrusions();
        });
        if (next == object->layers().end()) {
            boost::nowide::cerr << "Automatic first-layer lowering failed: no later object layer has extrusions." << std::endl;
            return false;
        }
        const double distance = (*next)->slice_z - first_z;
        if (!std::isfinite(distance))
            return false;

        for (const PrintInstance &instance : object->instances()) {
            const size_t id = instance.model_instance->id().id;
            if (lowered[id] + distance > limit) {
                boost::nowide::cerr << "Automatic first-layer lowering failed: the next printable layer exceeds the "
                                   << limit << " mm limit." << std::endl;
                return false;
            }
            bool found = false;
            for (ModelObject *source : model.objects) {
                if (source->id() != object->model_object()->id())
                    continue;
                for (size_t i = 0; i < source->instances.size(); ++i)
                    if (source->instances[i]->id().id == id) {
                        adjustments.push_back({source, i, distance});
                        found = true;
                        break;
                    }
            }
            if (!found)
                return false;
        }
    }
    if (adjustments.empty())
        return false;

    for (const Adjustment &adjustment : adjustments) {
        const size_t id = adjustment.object->instances[adjustment.instance]->id().id;
        adjustment.object->translate_instance(adjustment.instance, Vec3d(0., 0., -adjustment.distance / z_scale));
        lowered[id] += adjustment.distance;
        const std::string message = (boost::format("Automatically lowered object '%1%' instance %2% by %3% mm "
                                                   "(total %4% mm); geometry below the build plate is removed.")
                                     % adjustment.object->name % (adjustment.instance + 1) % adjustment.distance % lowered[id]).str();
        boost::nowide::cerr << "Warning: " << message << std::endl;
        BOOST_LOG_TRIVIAL(warning) << message;
        record_adjustment(adjustment.object->name, adjustment.instance + 1, lowered[id]);
    }
    return true;
}

bool FirstLayerRetry::try_fix(const SlicingErrors &errors, Print &print, Model &model, const DynamicPrintConfig &config,
                              std::vector<PrintBase::SlicingStatus> &warnings, size_t warnings_before,
                              const std::function<void(const std::string &, size_t, double)> &record_adjustment)
{
    if (errors.errors_.empty())
        return false;
    std::vector<size_t> empty_first_layers;
    for (const SlicingError &error : errors.errors_) {
        if (error.reason() != SlicingError::Reason::EmptyFirstLayer)
            return false;
        empty_first_layers.push_back(error.objectId());
    }
    if (!lower_empty_first_layers(print, model, empty_first_layers, m_lowered, record_adjustment))
        return false;
    // Support deduplication mutates other objects' paths, so rebuild the whole print.
    warnings.erase(warnings.begin() + warnings_before, warnings.end());
    print.clear();
    print.apply(model, config);
    const auto retry_error = print.validate();
    if (!retry_error.string.empty() &&
        !(retry_error.type == STRING_EXCEPT_LAYER_HEIGHT_EXCEEDS_LIMIT && print.get_no_check_flag()))
        throw SlicingError(retry_error.string);
    if (print.empty())
        throw SlicingError("Automatic first-layer cutting left no printable objects.");
    return true;
}

} // namespace TBFixes
} // namespace Slic3r
