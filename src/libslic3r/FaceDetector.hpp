#ifndef slic3r_FaceDetector_hpp_
#define slic3r_FaceDetector_hpp_

#include "Point.hpp"
#include <vector>

namespace Slic3r {
class ModelObject;
class TriangleMesh;

class FaceDetector {
public:
#if defined(SLIC3R_HEADLESS)
	FaceDetector(std::vector<TriangleMesh>&, std::vector<Transform3d>&, double) {}
#else
	FaceDetector(std::vector<TriangleMesh>& tms, std::vector<Transform3d>& transfos, double sample_interval)
		: m_meshes(tms), m_transfos(transfos), m_sample_interval(sample_interval) {}
#endif

	void detect_exterior_face();

private:
#if !defined(SLIC3R_HEADLESS)
	std::vector<TriangleMesh>& m_meshes;
	std::vector<Transform3d>& m_transfos;
	double m_sample_interval;
#endif
};

}

#endif // #ifndef slic3r_FaceDetector_hpp_
