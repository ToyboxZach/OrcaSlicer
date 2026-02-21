#pragma once

#if defined(SLIC3R_HEADLESS) && !defined(SLIC3R_GUI)

#include <cstdlib>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "libslic3r/Arrange.hpp"
#include "libslic3r/Config.hpp"
#include "libslic3r/GCode/GCodeProcessor.hpp"
#include "libslic3r/Model.hpp"
#include "libslic3r/Print.hpp"
#include "libslic3r/PrintConfig.hpp"


#ifndef _u8L
#define _u8L(x) x
#endif

#ifndef BBL_JSON_KEY_NAME
#define BBL_JSON_KEY_NAME "name"
#endif
#ifndef BBL_JSON_KEY_FROM
#define BBL_JSON_KEY_FROM "from"
#endif
#ifndef BBL_JSON_KEY_TYPE
#define BBL_JSON_KEY_TYPE "type"
#endif
#ifndef BBL_JSON_KEY_FILAMENT_ID
#define BBL_JSON_KEY_FILAMENT_ID "filament_id"
#endif

namespace Slic3r {

constexpr float WIPE_TOWER_DEFAULT_X_POS = 0.0f;
constexpr float WIPE_TOWER_DEFAULT_Y_POS = 0.0f;
constexpr float I3_WIPE_TOWER_DEFAULT_X_POS = 0.0f;
constexpr float I3_WIPE_TOWER_DEFAULT_Y_POS = 0.0f;
constexpr int MAX_PLATE_COUNT = 36;

namespace GUI {

using GCodeResult = GCodeProcessorResult;

class BitmapCache
{
public:
    static void parse_color4(const std::string& color, unsigned char rgba[4])
    {
        rgba[0] = rgba[1] = rgba[2] = 0;
        rgba[3] = 255;
        if (color.empty())
            return;
        std::string hex = color;
        if (hex[0] == '#')
            hex.erase(0, 1);
        if (hex.size() == 6 || hex.size() == 8) {
            auto hex_to_byte = [](const std::string& s, size_t pos) -> unsigned char {
                return static_cast<unsigned char>(std::strtoul(s.substr(pos, 2).c_str(), nullptr, 16));
            };
            rgba[0] = hex_to_byte(hex, 0);
            rgba[1] = hex_to_byte(hex, 2);
            rgba[2] = hex_to_byte(hex, 4);
            if (hex.size() == 8)
                rgba[3] = hex_to_byte(hex, 6);
        }
    }
};

inline const std::vector<int>& get_min_flush_volumes(const DynamicPrintConfig& print_config, int)
{
    static std::vector<int> values;
    const auto* filament_type = dynamic_cast<const ConfigOptionStrings*>(print_config.option("filament_type"));
    const size_t count = filament_type ? filament_type->values.size() : 1;
    values.assign(count, 0);
    return values;
}

class PartPlate
{
public:
    PartPlate(Model* model, PrinterTechnology printer_technology)
        : m_model(model)
        , m_printer_technology(printer_technology)
    {
    }

    DynamicPrintConfig* config() { return &m_config; }
    const DynamicPrintConfig* config() const { return &m_config; }

    void get_print(PrintBase** print, GCodeResult** gcode_result, int* print_index)
    {
        if (print)
            *print = &m_print;
        if (gcode_result)
            *gcode_result = &m_gcode_result;
        if (print_index)
            *print_index = 0;
    }

    GCodeProcessorResult* get_slice_result() { return &m_gcode_result; }
    bool is_slice_result_valid() const { return m_slice_result_valid; }
    void update_slice_result_valid_state(bool valid) { m_slice_result_valid = valid; }

    const Pointfs& get_shape() const { return m_shape; }
    const std::vector<Pointfs>& get_extruder_areas() const { return m_extruder_areas; }
    const std::vector<double>& get_extruder_heights() const { return m_extruder_heights; }

    void set_shape(const Pointfs& shape) { m_shape = shape; }
    void set_extruder_areas(const std::vector<Pointfs>& areas) { m_extruder_areas = areas; }
    void set_extruder_heights(const std::vector<double>& heights) { m_extruder_heights = heights; }

    std::string get_tmp_gcode_path() const { return m_tmp_gcode_path; }
    void set_tmp_gcode_path(const std::string& path) { m_tmp_gcode_path = path; }

    std::vector<int> get_extruders_under_cli(bool, const DynamicPrintConfig& print_config) const
    {
        std::vector<int> result;
        const auto* filament_type = dynamic_cast<const ConfigOptionStrings*>(print_config.option("filament_type"));
        const size_t count = filament_type ? filament_type->values.size() : 1;
        result.reserve(count);
        for (size_t i = 0; i < count; ++i)
            result.push_back(static_cast<int>(i + 1));
        return result;
    }

    bool check_tpu_printable_status(const DynamicPrintConfig&, const std::vector<int>&) const { return true; }

    FilamentMapMode get_real_filament_map_mode(const DynamicPrintConfig&) const
    {
        return fmmAutoForFlush;
    }

    std::vector<int> get_real_filament_maps(const DynamicPrintConfig& print_config) const
    {
        std::vector<int> result;
        const auto* filament_type = dynamic_cast<const ConfigOptionStrings*>(print_config.option("filament_type"));
        const size_t count = filament_type ? filament_type->values.size() : 1;
        result.assign(count, 1);
        return result;
    }

    void set_filament_maps(const std::vector<int>& maps) { m_filament_maps = maps; }

    BoundingBoxf3 get_objects_bounding_box() const { return BoundingBoxf3(); }

    Vec3d estimate_wipe_tower_size(const DynamicPrintConfig&, float& width, float& volume, int, int, bool, bool)
    {
        width = 0.0f;
        volume = 0.0f;
        return Vec3d::Zero();
    }

    ArrangePolygon estimate_wipe_tower_polygon(const DynamicPrintConfig&, int, Vec3d& position, Vec3d& size, int, int, bool)
    {
        position = Vec3d::Zero();
        size = Vec3d::Zero();
        return ArrangePolygon();
    }

    void translate_all_instance(const Vec3d&) {}
    void duplicate_all_instance(int, bool, const std::map<int, bool>&) {}

    bool contain_instance(size_t, size_t) const { return true; }
    bool intersect_instance(size_t, size_t) const { return false; }

    int printable_instance_size() const
    {
        if (!m_model)
            return 0;
        int count = 0;
        for (const ModelObject* object : m_model->objects)
            for (const ModelInstance* inst : object->instances)
                if (inst->printable)
                    ++count;
        return count;
    }

    bool has_printable_instances() const { return printable_instance_size() > 0; }

    Vec3d get_origin() const { return m_origin; }
    PrintSequence get_print_seq() const { return PrintSequence::ByDefault; }
    BedType get_bed_type() const { return btDefault; }
    const std::vector<BoundingBoxf3>& get_exclude_areas() const { return m_exclude_areas; }

    void lock(bool) {}

private:
    Model* m_model { nullptr };
    PrinterTechnology m_printer_technology { ptFFF };
    DynamicPrintConfig m_config;
    Print m_print;
    GCodeProcessorResult m_gcode_result;
    Pointfs m_shape;
    std::vector<Pointfs> m_extruder_areas;
    std::vector<double> m_extruder_heights;
    std::vector<int> m_filament_maps;
    std::vector<BoundingBoxf3> m_exclude_areas;
    Vec3d m_origin { Vec3d::Zero() };
    std::string m_tmp_gcode_path;
    bool m_slice_result_valid { false };
};

class PartPlateList
{
public:
    PartPlateList(void*, Model* models, PrinterTechnology printer_technology)
        : m_plate(models, printer_technology)
    {
    }

    int get_plate_count() const { return 1; }
    PartPlate* get_plate(int index) { return (index == 0) ? &m_plate : nullptr; }
    PartPlate* get_curr_plate() { return &m_plate; }

    void reset_size(int width, int depth, int height, bool, bool = false)
    {
        m_width = width;
        m_depth = depth;
        m_height = height;
    }

    void set_shapes(const Pointfs& printable_area, const Pointfs&, const Pointfs&,
                    const std::vector<Pointfs>& extruder_areas, const std::vector<double>& extruder_heights,
                    const std::string&, double, double)
    {
        m_plate.set_shape(printable_area);
        m_plate.set_extruder_areas(extruder_areas);
        m_plate.set_extruder_heights(extruder_heights);
    }

    void get_plate_size(int& width, int& depth, int& height) const
    {
        width = m_width;
        depth = m_depth;
        height = m_height;
    }

    void load_from_3mf_structure(const PlateDataPtrs&) {}
    void store_to_3mf_structure(PlateDataPtrs&) const {}

    void preprocess_exclude_areas(const ArrangePolygons&, bool) {}
    void preprocess_exclude_areas(const ArrangePolygons&, bool, int) {}
    void preprocess_exclude_areas(const ArrangePolygons&, bool, int, double) {}
    void preprocess_nonprefered_areas(const ArrangePolygons&, int) {}
    bool preprocess_arrange_polygon(size_t, size_t, ArrangePolygon&, bool) { return false; }
    bool preprocess_arrange_polygon_other_locked(size_t, size_t, ArrangePolygon&, bool) { return false; }
    void postprocess_arrange_polygon(ArrangePolygon&, bool) {}
    void postprocess_bed_index_for_current_plate(ArrangePolygon&) {}
    void postprocess_bed_index_for_selected(ArrangePolygon&) {}
    void rebuild_plates_after_arrangement(bool = false, bool = false, int = 0) {}
    void clear() {}
    void clear(bool, bool, bool, int = 0) {}
    void lock_plate(int, bool) {}
    void select_plate(int) {}
    void reload_all_objects(bool, int) {}

    Vec3d compute_origin_using_new_size(int, int, int) const { return Vec3d::Zero(); }

private:
    PartPlate m_plate;
    int m_width { 0 };
    int m_depth { 0 };
    int m_height { 0 };
};

} // namespace GUI
} // namespace Slic3r

#endif
