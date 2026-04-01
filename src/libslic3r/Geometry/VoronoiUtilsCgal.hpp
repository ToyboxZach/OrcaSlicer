#ifndef slic3r_VoronoiUtilsCgal_hpp_
#define slic3r_VoronoiUtilsCgal_hpp_

#include <boost/polygon/polygon.hpp>
#include <iterator>

#include "Voronoi.hpp"
#include "../Arachne/utils/PolygonsSegmentIndex.hpp"

namespace Slic3r::Geometry {
class VoronoiDiagram;

class VoronoiUtilsCgal
{
public:
    // Check if the Voronoi diagram is planar using CGAL sweeping edge algorithm for enumerating all intersections between lines.
        static bool is_voronoi_diagram_planar_intersection(const VoronoiDiagram &voronoi_diagram);

    // Check if the Voronoi diagram is planar using verification that all neighboring edges are ordered CCW for each vertex.
    template<typename SegmentIterator>
    static typename boost::polygon::enable_if<
        typename boost::polygon::gtl_if<typename boost::polygon::is_segment_concept<
            typename boost::polygon::geometry_concept<typename std::iterator_traits<SegmentIterator>::value_type>::type>::type>::type,
        bool>::type
    is_voronoi_diagram_planar_angle(const VoronoiDiagram &voronoi_diagram, SegmentIterator segment_begin, SegmentIterator segment_end);
};

#if defined(SLIC3R_HEADLESS)
inline bool VoronoiUtilsCgal::is_voronoi_diagram_planar_intersection(const VoronoiDiagram &voronoi_diagram)
{
    (void)voronoi_diagram;
    return true;
}

template<typename SegmentIterator>
inline typename boost::polygon::enable_if<
    typename boost::polygon::gtl_if<typename boost::polygon::is_segment_concept<
        typename boost::polygon::geometry_concept<typename std::iterator_traits<SegmentIterator>::value_type>::type>::type>::type,
    bool>::type
VoronoiUtilsCgal::is_voronoi_diagram_planar_angle(const VoronoiDiagram &voronoi_diagram, SegmentIterator segment_begin, SegmentIterator segment_end)
{
    (void)voronoi_diagram;
    (void)segment_begin;
    (void)segment_end;
    return true;
}
#endif
} // namespace Slic3r::Geometry

#endif // slic3r_VoronoiUtilsCgal_hpp_
