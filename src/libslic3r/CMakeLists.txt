cmake_minimum_required(VERSION 3.13)
project(libslic3r)

include(PrecompiledHeader)

if(NOT DEFINED ORCA_CHECK_GCODE_PLACEHOLDERS)
    set(ORCA_CHECK_GCODE_PLACEHOLDERS "0")
endif()
message("!!! CONFIGURE VERSION!!!")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libslic3r_version.h.in ${CMAKE_CURRENT_BINARY_DIR}/libslic3r_version.h @ONLY)
if (MINGW)
    add_compile_options(-Wa,-mbig-obj)
endif ()

set(OpenVDBUtils_SOURCES "")
#if (TARGET OpenVDB::openvdb)
  #  set(OpenVDBUtils_SOURCES OpenVDBUtils.cpp OpenVDBUtils.hpp)
#endif()

option(BUILD_SHARED_LIBS "Build shared libs" OFF)

set(lisbslic3r_sources
    AABBMesh.cpp
    AABBMesh.hpp
    AABBTreeIndirect.hpp
    AABBTreeLines.hpp
    Algorithm/LineSplit.cpp
    Algorithm/LineSplit.hpp
    Algorithm/RegionExpansion.cpp
    Algorithm/RegionExpansion.hpp
    AnyPtr.hpp
    AppConfig.cpp
    AppConfig.hpp
    Arachne/BeadingStrategy/BeadingStrategy.cpp
    Arachne/BeadingStrategy/BeadingStrategyFactory.cpp
    Arachne/BeadingStrategy/BeadingStrategyFactory.hpp
    Arachne/BeadingStrategy/BeadingStrategy.hpp
    Arachne/BeadingStrategy/DistributedBeadingStrategy.cpp
    Arachne/BeadingStrategy/DistributedBeadingStrategy.hpp
    Arachne/BeadingStrategy/LimitedBeadingStrategy.cpp
    Arachne/BeadingStrategy/LimitedBeadingStrategy.hpp
    Arachne/BeadingStrategy/OuterWallInsetBeadingStrategy.cpp
    Arachne/BeadingStrategy/OuterWallInsetBeadingStrategy.hpp
    Arachne/BeadingStrategy/RedistributeBeadingStrategy.cpp
    Arachne/BeadingStrategy/RedistributeBeadingStrategy.hpp
    Arachne/BeadingStrategy/WideningBeadingStrategy.cpp
    Arachne/BeadingStrategy/WideningBeadingStrategy.hpp
    Arachne/SkeletalTrapezoidation.cpp
    Arachne/SkeletalTrapezoidationEdge.hpp
    Arachne/SkeletalTrapezoidationGraph.cpp
    Arachne/SkeletalTrapezoidationGraph.hpp
    Arachne/SkeletalTrapezoidation.hpp
    Arachne/SkeletalTrapezoidationJoint.hpp
    Arachne/utils/ExtrusionJunction.hpp
    Arachne/utils/ExtrusionLine.cpp
    Arachne/utils/ExtrusionLine.hpp
    Arachne/utils/HalfEdgeGraph.hpp
    Arachne/utils/HalfEdge.hpp
    Arachne/utils/HalfEdgeNode.hpp
    Arachne/utils/PolygonsPointIndex.hpp
    Arachne/utils/PolygonsSegmentIndex.hpp
    Arachne/utils/PolylineStitcher.cpp
    Arachne/utils/PolylineStitcher.hpp
    Arachne/utils/SparseGrid.hpp
    Arachne/utils/SparseLineGrid.hpp
    Arachne/utils/SparsePointGrid.hpp
    Arachne/utils/SquareGrid.cpp
    Arachne/utils/SquareGrid.hpp
    Arachne/WallToolPaths.cpp
    Arachne/WallToolPaths.hpp
    ArcFitter.cpp
    ArcFitter.hpp
    Arrange.cpp
    Arrange.hpp
    BlacklistedLibraryCheck.cpp
    BlacklistedLibraryCheck.hpp
    BoundingBox.cpp
    BoundingBox.hpp
    BridgeDetector.cpp
    BridgeDetector.hpp
    Brim.cpp
    BrimEarsPoint.hpp
    Brim.hpp
    BuildVolume.cpp
    BuildVolume.hpp
    calib.cpp
    calib.hpp
    Circle.cpp
    Circle.hpp
    clipper.cpp
    clipper.hpp
    ClipperUtils.cpp
    ClipperUtils.hpp
    Clipper2Utils.cpp
    Clipper2Utils.hpp
    ClipperZUtils.hpp
    Color.cpp
    Color.hpp
    CommonDefs.hpp
    Config.cpp
    Config.hpp
    CustomGCode.cpp
    CustomGCode.hpp
    CutUtils.cpp
    CutUtils.hpp
    EdgeGrid.cpp
    EdgeGrid.hpp
    ElephantFootCompensation.cpp
    ElephantFootCompensation.hpp
    Emboss.cpp
    Emboss.hpp
    EmbossShape.hpp
    enum_bitmask.hpp
    Execution/Execution.hpp
    Execution/ExecutionSeq.hpp
    Execution/ExecutionTBB.hpp
    ExPolygon.cpp
    ExPolygon.hpp
    ExPolygonSerialize.hpp
    ExPolygonsIndex.cpp
    ExPolygonsIndex.hpp
    Extruder.cpp
    Extruder.hpp
    ExtrusionEntityCollection.cpp
    ExtrusionEntityCollection.hpp
    ExtrusionEntity.cpp
    ExtrusionEntity.hpp
    ExtrusionSimulator.cpp
    ExtrusionSimulator.hpp
    FaceDetector.cpp
    FaceDetector.hpp
    Feature/FuzzySkin/FuzzySkin.cpp
    Feature/FuzzySkin/FuzzySkin.hpp
    Feature/Interlocking/InterlockingGenerator.cpp
    Feature/Interlocking/InterlockingGenerator.hpp
    Feature/Interlocking/VoxelUtils.cpp
    Feature/Interlocking/VoxelUtils.hpp
    FileParserError.hpp
    Fill/Fill3DHoneycomb.cpp
    Fill/Fill3DHoneycomb.hpp
    Fill/FillAdaptive.cpp
    Fill/FillAdaptive.hpp
    Fill/FillBase.cpp
    Fill/FillBase.hpp
    Fill/FillConcentric.cpp
    Fill/FillConcentric.hpp
    Fill/FillConcentricInternal.cpp
    Fill/FillConcentricInternal.hpp
    Fill/Fill.cpp
    Fill/FillCrossHatch.cpp
    Fill/FillCrossHatch.hpp
    Fill/FillGyroid.cpp
    Fill/FillGyroid.hpp
    Fill/FillHoneycomb.cpp
    Fill/FillHoneycomb.hpp
    Fill/Fill.hpp
    Fill/FillLightning.cpp
    Fill/FillLightning.hpp
    Fill/FillLine.cpp
    Fill/FillLine.hpp
    Fill/FillPlanePath.cpp
    Fill/FillPlanePath.hpp
    Fill/FillRectilinear.cpp
    Fill/FillRectilinear.hpp
    Fill/FillTpmsD.cpp
    Fill/FillTpmsD.hpp
    Fill/FillTpmsFK.cpp
    Fill/FillTpmsFK.hpp
    Fill/Lightning/DistanceField.cpp
    Fill/Lightning/DistanceField.hpp
    Fill/Lightning/Generator.cpp
    Fill/Lightning/Generator.hpp
    Fill/Lightning/Layer.cpp
    Fill/Lightning/Layer.hpp
    Fill/Lightning/TreeNode.cpp
    Fill/Lightning/TreeNode.hpp
    Flow.cpp
    Flow.hpp
    FlushVolCalc.cpp
    FlushVolCalc.hpp
    Format/3mf.cpp
    Format/3mf.hpp
    Format/AMF.cpp
    Format/AMF.hpp
    Format/bbs_3mf.cpp
    Format/bbs_3mf.hpp
    format.hpp
    Format/OBJ.cpp
    Format/OBJ.hpp
    Format/objparser.cpp
    Format/objparser.hpp
    Format/SL1.cpp
    Format/SL1.hpp
   # Format/STEP.cpp
  #  Format/STEP.hpp
    Format/STL.cpp
    Format/STL.hpp
    Format/svg.cpp
    Format/svg.hpp

    Format/ZipperArchiveImport.cpp
    Format/ZipperArchiveImport.hpp
    GCode/AdaptivePAInterpolator.cpp
    GCode/AdaptivePAInterpolator.hpp
    GCode/AdaptivePAProcessor.cpp
    GCode/AdaptivePAProcessor.hpp
    GCode/AvoidCrossingPerimeters.cpp
    GCode/AvoidCrossingPerimeters.hpp
    GCode/ConflictChecker.cpp
    GCode/ConflictChecker.hpp
    GCode/CoolingBuffer.cpp
    GCode/CoolingBuffer.hpp
    GCode/TimelapsePosPicker.cpp
    GCode/TimelapsePosPicker.hpp
    GCode.cpp
    GCode/ExtrusionProcessor.hpp
    GCode/FanMover.cpp
    GCode/FanMover.hpp
    GCode/GCodeProcessor.cpp
    GCode/GCodeProcessor.hpp
    GCode.hpp
    GCode/PchipInterpolatorHelper.cpp
    GCode/PchipInterpolatorHelper.hpp
    GCode/PostProcessor.cpp
    GCode/PostProcessor.hpp
    GCode/PressureEqualizer.cpp
    GCode/PressureEqualizer.hpp
    GCode/PrintExtents.cpp
    GCode/PrintExtents.hpp
    GCodeReader.cpp
    GCodeReader.hpp
    GCode/RetractWhenCrossingPerimeters.cpp
    GCode/RetractWhenCrossingPerimeters.hpp
    GCode/SeamPlacer.cpp
    GCode/SeamPlacer.hpp
    #GCodeSender.cpp
    #GCodeSender.hpp
    GCode/SmallAreaInfillFlowCompensator.cpp
    GCode/SmallAreaInfillFlowCompensator.hpp
    GCode/SpiralVase.cpp
    GCode/SpiralVase.hpp
    GCode/ThumbnailData.cpp
    GCode/ThumbnailData.hpp
    GCode/Thumbnails.cpp
    GCode/Thumbnails.hpp
    GCode/ToolOrdering.cpp
    GCode/ToolOrdering.hpp
    GCode/WipeTower2.cpp
    GCode/WipeTower2.hpp
    GCode/WipeTower.cpp
    GCode/WipeTower.hpp
    GCodeWriter.cpp
    GCodeWriter.hpp
    Geometry/ArcWelder.hpp
    Geometry/ArcWelder.cpp
    Geometry/Bicubic.hpp
    Geometry/Circle.cpp
    Geometry/Circle.hpp
    Geometry/ConvexHull.cpp
    Geometry/ConvexHull.hpp
    Geometry.cpp
    Geometry/Curves.hpp
    Geometry.hpp
    Geometry/MedialAxis.cpp
    Geometry/MedialAxis.hpp
    Geometry/Voronoi.cpp
    Geometry/Voronoi.hpp
    Geometry/VoronoiOffset.cpp
    Geometry/VoronoiOffset.hpp
    Geometry/VoronoiUtilsCgal.cpp
    Geometry/VoronoiUtilsCgal.hpp
    Geometry/VoronoiUtils.cpp
    Geometry/VoronoiUtils.hpp
    Geometry/VoronoiVisualUtils.hpp
    Int128.hpp
    KDTreeIndirect.hpp
    Layer.cpp
    Layer.hpp
    LayerRegion.cpp
    libslic3r.cpp
    libslic3r.h
    Line.cpp
    Line.hpp
    LocalesUtils.cpp
    LocalesUtils.hpp
    MarchingSquares.hpp
    Measure.cpp
    Measure.hpp
    MeasureUtils.hpp
    MeshSplitImpl.hpp
    MinAreaBoundingBox.cpp
    MinAreaBoundingBox.hpp
    MinimumSpanningTree.cpp
    MinimumSpanningTree.hpp
    miniz_extension.cpp
    miniz_extension.hpp
    ModelArrange.cpp
    ModelArrange.hpp
    Model.cpp
    Model.hpp
    MTUtils.hpp
    MultiMaterialSegmentation.cpp
    MultiMaterialSegmentation.hpp
    MultiPoint.cpp
    MultiPoint.hpp
    MutablePolygon.cpp
    MutablePolygon.hpp
    MutablePriorityQueue.hpp
    NormalUtils.cpp
    NormalUtils.hpp
    NSVGUtils.cpp
    NSVGUtils.hpp
    ObjColorUtils.cpp
    ObjColorUtils.hpp
    ObjectID.cpp
    ObjectID.hpp
    Optimize/BruteforceOptimizer.hpp
    Optimize/NLoptOptimizer.hpp
    Optimize/Optimizer.hpp
    Orient.cpp
    Orient.hpp
    ParameterUtils.cpp
    ParameterUtils.hpp
    pchheader.cpp
    pchheader.hpp
    PerimeterGenerator.cpp
    PerimeterGenerator.hpp
    PlaceholderParser.cpp
    PlaceholderParser.hpp
    Platform.cpp
    Platform.hpp
    PNGReadWrite.cpp
    PNGReadWrite.hpp
    Point.cpp
    Point.hpp
    Polygon.cpp
    Polygon.hpp
    PolygonTrimmer.cpp
    PolygonTrimmer.hpp
    Polyline.cpp
    Polyline.hpp
    PresetBundle.cpp
    PresetBundle.hpp
    Preset.cpp
    Preset.hpp
    PrincipalComponents2D.cpp
    PrincipalComponents2D.hpp
    PrintApply.cpp
    PrintBase.cpp
    PrintBase.hpp
    MaterialType.cpp
    MaterialType.hpp
    PrintConfig.cpp
    PrintConfig.hpp
    Print.cpp
    Print.hpp
    PrintSupportDedup.cpp
    PrintObject.cpp
    PrintObjectSlice.cpp
    PrintRegion.cpp
    ProjectTask.cpp
    ProjectTask.hpp
    QuadricEdgeCollapse.cpp
    QuadricEdgeCollapse.hpp
    Semver.cpp
    Shape/TextShape.cpp
    Shape/TextShape.hpp
    ShortEdgeCollapse.cpp
    ShortEdgeCollapse.hpp
    ShortestPath.cpp
    ShortestPath.hpp
    SLA/AGGRaster.hpp
    SLA/BoostAdapter.hpp
    SLA/Clustering.cpp
    SLA/Clustering.hpp
    SLA/ConcaveHull.cpp
    SLA/ConcaveHull.hpp
    SLA/Concurrency.hpp
    SLA/Hollowing.cpp
    SLA/Hollowing.hpp
    SLA/IndexedMesh.cpp
    SLA/IndexedMesh.hpp
    SLA/JobController.hpp
    SLA/Pad.cpp
    SLA/Pad.hpp
    SLAPrint.cpp
    SLAPrint.hpp
    SLAPrintSteps.cpp
    SLAPrintSteps.hpp
    SLA/RasterBase.cpp
    SLA/RasterBase.hpp
    SLA/RasterToPolygons.cpp
    SLA/RasterToPolygons.hpp
    SLA/ReprojectPointsOnMesh.hpp
    SLA/Rotfinder.cpp
    SLA/Rotfinder.hpp
    SLA/SpatIndex.cpp
    SLA/SpatIndex.hpp
    SLA/SupportPointGenerator.cpp
    SLA/SupportPointGenerator.hpp
    SLA/SupportPoint.hpp
    SLA/SupportTreeBuilder.cpp
    SLA/SupportTreeBuilder.hpp
    SLA/SupportTreeBuildsteps.cpp
    SLA/SupportTreeBuildsteps.hpp
    SLA/SupportTree.cpp
    SLA/SupportTree.hpp
    #SLA/SupportTreeIGL.cpp
    SLA/SupportTreeMesher.cpp
    SLA/SupportTreeMesher.hpp
    SlicesToTriangleMesh.cpp
    SlicesToTriangleMesh.hpp
    SlicingAdaptive.cpp
    SlicingAdaptive.hpp
    Slicing.cpp
    Slicing.hpp
    Support/SupportCommon.cpp
    Support/SupportCommon.hpp
    Support/SupportLayer.hpp
    Support/SupportMaterial.cpp
    Support/SupportMaterial.hpp
    Support/SupportParameters.hpp
    Support/SupportSpotsGenerator.cpp
    Support/SupportSpotsGenerator.hpp
    Support/TreeModelVolumes.cpp
    Support/TreeModelVolumes.hpp
    Support/TreeSupport3D.cpp
    Support/TreeSupport3D.hpp
    Support/TreeSupportCommon.hpp
    Support/TreeSupport.cpp
    Support/TreeSupport.hpp
    SurfaceCollection.cpp
    SurfaceCollection.hpp
    Surface.cpp
    Surface.hpp
    SurfaceMesh.hpp
    SVG.cpp
    SVG.hpp
    Technologies.hpp
    Tesselate.cpp
    Tesselate.hpp
    TextConfiguration.hpp
    Thread.cpp
    Thread.hpp
    Time.cpp
    Time.hpp
    Timer.cpp
    Timer.hpp
    TriangleMesh.cpp
    TriangleMesh.hpp
    TriangleMeshDeal.cpp
    TriangleMeshDeal.hpp
    TriangleMeshSlicer.cpp
    TriangleMeshSlicer.hpp
    TriangleSelector.cpp
    TriangleSelector.hpp
    TriangleSetSampling.cpp
    TriangleSetSampling.hpp
    Triangulation.cpp
    Triangulation.hpp
    TriangulateWall.cpp
    TriangulateWall.hpp
    utils.cpp
    Utils.hpp
    VariableWidth.cpp
    VariableWidth.hpp
    Zipper.cpp
    Zipper.hpp
    FilamentGroup.hpp
    FilamentGroup.cpp
    FilamentGroupUtils.hpp
    FilamentGroupUtils.cpp
    GCode/ToolOrderUtils.hpp
    GCode/ToolOrderUtils.cpp
    FlushVolPredictor.hpp
    FlushVolPredictor.cpp
)

# Headless builds exclude SLA/resin features and heavy dependencies (PNG, TextShape, VoronoiCGAL)
if (SLIC3R_HEADLESS)
    list(REMOVE_ITEM lisbslic3r_sources
        Geometry/VoronoiUtilsCgal.cpp
        Geometry/VoronoiUtilsCgal.hpp
        ObjColorUtils.cpp
        ObjColorUtils.hpp
        PNGReadWrite.cpp
        PNGReadWrite.hpp
        Format/SL1.cpp
        Format/SL1.hpp
        Shape/TextShape.cpp
        Shape/TextShape.hpp
        SLA/Clustering.cpp
        SLA/Clustering.hpp
        SLA/ConcaveHull.cpp
        SLA/ConcaveHull.hpp
        SLA/Hollowing.cpp
        SLA/Hollowing.hpp
        SLA/IndexedMesh.cpp
        SLA/IndexedMesh.hpp
        SLA/Pad.cpp
        SLA/Pad.hpp
        SLAPrint.cpp
        SLAPrint.hpp
        SLAPrintSteps.cpp
        SLAPrintSteps.hpp
        SLA/RasterBase.cpp
        SLA/RasterBase.hpp
        SLA/RasterToPolygons.cpp
        SLA/RasterToPolygons.hpp
        SLA/Rotfinder.cpp
        SLA/Rotfinder.hpp
        SLA/SpatIndex.cpp
        SLA/SpatIndex.hpp
        SLA/SupportPointGenerator.cpp
        SLA/SupportPointGenerator.hpp
        SLA/SupportTreeBuilder.cpp
        SLA/SupportTreeBuilder.hpp
        SLA/SupportTreeBuildsteps.cpp
        SLA/SupportTreeBuildsteps.hpp
        SLA/SupportTree.cpp
        SLA/SupportTree.hpp
        SLA/SupportTreeMesher.cpp
        SLA/SupportTreeMesher.hpp
        ../slic3r/Utils/ColorSpaceConvert.hpp

    )
    list(APPEND lisbslic3r_sources
        Format/svg.cpp
        Format/svg.hpp
        IntersectionPoints.cpp
        IntersectionPoints.hpp
        MeshBoolean.cpp
        MeshBoolean.hpp
    )
endif ()

if (APPLE)
    list(APPEND lisbslic3r_sources
            MacUtils.mm
            Format/ModelIO.hpp
            Format/ModelIO.mm
        )
endif ()

add_library(libslic3r STATIC ${lisbslic3r_sources} 
    "${CMAKE_CURRENT_BINARY_DIR}/libslic3r_version.h"
    ${OpenVDBUtils_SOURCES})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${lisbslic3r_sources})

if (SLIC3R_HEADLESS)
    target_sources(libslic3r PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../slic3r/GUI/PartPlate.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/../slic3r/GUI/PartPlate.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/../slic3r/Utils/ColorSpaceConvert.cpp
    )
endif ()

if (SLIC3R_STATIC)
    set(CGAL_Boost_USE_STATIC_LIBS ON CACHE BOOL "" FORCE)
endif ()
set(CGAL_DO_NOT_WARN_ABOUT_CMAKE_BUILD_TYPE ON CACHE BOOL "" FORCE)

cmake_policy(PUSH)
cmake_policy(SET CMP0011 NEW)
#set(CMAKE_FIND_DEBUG_MODE TRUE)

if (EMSCRIPTEN)
    set(CGAL_INCLUDE_DIRS "${CMAKE_PREFIX_PATH}/include")
    set(CGAL_FOUND TRUE)
    if (NOT TARGET CGAL::CGAL)
        add_library(CGAL::CGAL INTERFACE IMPORTED)
        set_target_properties(CGAL::CGAL PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CGAL_INCLUDE_DIRS}"
        )
    endif ()
    message(STATUS "WASM CGAL: includes=${CGAL_INCLUDE_DIRS}, libs=(header-only)")
else ()
    if (NOT SLIC3R_HEADLESS)
        set(CGAL_INCLUDE_DIRS "${CMAKE_PREFIX_PATH}/include")
        set(CGAL_FOUND TRUE)
        if (NOT TARGET CGAL::CGAL)
            add_library(CGAL::CGAL INTERFACE IMPORTED)
            set_target_properties(CGAL::CGAL PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${CGAL_INCLUDE_DIRS}"
            )
        endif ()
        message(STATUS "WASM CGAL: includes=${CGAL_INCLUDE_DIRS}, libs=(header-only)")
    else ()
        find_package(CGAL REQUIRED)
    endif ()
endif ()
#find_package(OpenCV REQUIRED core)
cmake_policy(POP)

if (NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    add_library(libslic3r_cgal STATIC 
        CutSurface.hpp CutSurface.cpp
        IntersectionPoints.hpp IntersectionPoints.cpp
        MeshBoolean.hpp MeshBoolean.cpp
        TryCatchSignal.hpp TryCatchSignal.cpp
        Triangulation.hpp Triangulation.cpp
    )
    target_include_directories(libslic3r_cgal PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
endif ()

if (NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    # Reset compile options of libslic3r_cgal. Despite it being linked privately, CGAL options
    # (-frounding-math) still propagate to dependent libs which is not desired.
    get_target_property(_cgal_tgt CGAL::CGAL ALIASED_TARGET)
    if (NOT TARGET ${_cgal_tgt})
        set (_cgal_tgt CGAL::CGAL)
    endif ()
    get_target_property(_opts ${_cgal_tgt} INTERFACE_COMPILE_OPTIONS)
    if (_opts)
        set(_opts_bad "${_opts}")
        set(_opts_good "${_opts}")
        list(FILTER _opts_bad INCLUDE REGEX frounding-math)
        list(FILTER _opts_good EXCLUDE REGEX frounding-math)
        set_target_properties(${_cgal_tgt} PROPERTIES INTERFACE_COMPILE_OPTIONS "${_opts_good}")
        target_compile_options(libslic3r_cgal PRIVATE "${_opts_bad}")
    endif()

    target_link_libraries(libslic3r_cgal PRIVATE ${_cgal_tgt} eigen admesh libigl mcut boost_libs)
endif ()

if (MSVC AND "${CMAKE_SIZEOF_VOID_P}" STREQUAL "4") # 32 bit MSVC workaround
    target_compile_definitions(libslic3r_cgal PRIVATE CGAL_DO_NOT_USE_MPZF)
endif ()

set(_libslic3r_cgal_lib "")
if (TARGET libslic3r_cgal)
    set(_libslic3r_cgal_lib libslic3r_cgal)
endif ()

#encoding_check(libslic3r)

target_compile_definitions(libslic3r PUBLIC -DUSE_TBB -DTBB_USE_CAPTURED_EXCEPTION=0)
target_include_directories(libslic3r PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(libslic3r SYSTEM PUBLIC ${EXPAT_INCLUDE_DIRS})

set(_expat_libs "")
if (TARGET EXPAT::EXPAT)
    list(APPEND _expat_libs EXPAT::EXPAT)
elseif (TARGET expat)
    list(APPEND _expat_libs expat)
elseif (EXPAT_LIBRARIES)
    list(APPEND _expat_libs ${EXPAT_LIBRARIES})
endif ()

set(_nlopt_libs "")
if (TARGET NLopt::nlopt)
    list(APPEND _nlopt_libs NLopt::nlopt)
elseif (TARGET nlopt)
    list(APPEND _nlopt_libs nlopt)
elseif (NLOPT_LIBRARIES)
    list(APPEND _nlopt_libs ${NLOPT_LIBRARIES})
elseif (NLopt_LIBRARIES)
    list(APPEND _nlopt_libs ${NLopt_LIBRARIES})
endif ()
if (_nlopt_libs)
    if (NLOPT_INCLUDE_DIRS)
        target_include_directories(libslic3r SYSTEM PUBLIC ${NLOPT_INCLUDE_DIRS})
    elseif (NLopt_INCLUDE_DIR)
        target_include_directories(libslic3r SYSTEM PUBLIC ${NLopt_INCLUDE_DIR})
    endif ()
endif ()

set(_gmp_libs "")
if (EMSCRIPTEN)
    # Emscripten cross-compile: find_library doesn't work, use absolute paths
    set(GMP_LIB_DIR "${CMAKE_PREFIX_PATH}/lib")
    if (EXISTS "${GMP_LIB_DIR}/libmpfr.a")
        list(APPEND _gmp_libs "${GMP_LIB_DIR}/libmpfr.a")
        message(STATUS "Found MPFR (EMSCRIPTEN): ${GMP_LIB_DIR}/libmpfr.a")
    endif()
    if (EXISTS "${GMP_LIB_DIR}/libgmpxx.a")
        list(APPEND _gmp_libs "${GMP_LIB_DIR}/libgmpxx.a")
        message(STATUS "Found GMPXX (EMSCRIPTEN): ${GMP_LIB_DIR}/libgmpxx.a")
    endif()
    if (EXISTS "${GMP_LIB_DIR}/libgmp.a")
        list(APPEND _gmp_libs "${GMP_LIB_DIR}/libgmp.a")
        message(STATUS "Found GMP (EMSCRIPTEN): ${GMP_LIB_DIR}/libgmp.a")
    endif()
else()
    find_library(MPFR_LIBRARY mpfr HINTS ${CMAKE_PREFIX_PATH} PATH_SUFFIXES lib)
    if (MPFR_LIBRARY)
        list(APPEND _gmp_libs ${MPFR_LIBRARY})
        message(STATUS "Found MPFR: ${MPFR_LIBRARY}")
    else()
        message(WARNING "MPFR library not found")
    endif ()
    find_library(GMPXX_LIBRARY gmpxx HINTS ${CMAKE_PREFIX_PATH} PATH_SUFFIXES lib)
    if (GMPXX_LIBRARY)
        list(APPEND _gmp_libs ${GMPXX_LIBRARY})
        message(STATUS "Found GMPXX: ${GMPXX_LIBRARY}")
    else()
        message(WARNING "GMPXX library not found")
    endif ()
    find_library(GMP_LIBRARY gmp HINTS ${CMAKE_PREFIX_PATH} PATH_SUFFIXES lib)
    if (GMP_LIBRARY)
        list(APPEND _gmp_libs ${GMP_LIBRARY})
        message(STATUS "Found GMP: ${GMP_LIBRARY}")
    else()
        message(WARNING "GMP library not found")
    endif ()
endif()
message(STATUS "_gmp_libs = ${_gmp_libs}")

# Find the OCCT and related libraries
set(OpenCASCADE_DIR "${CMAKE_PREFIX_PATH}/lib/cmake/occt")
if(NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    find_package(OpenCASCADE REQUIRED)
    target_include_directories(libslic3r SYSTEM PUBLIC ${OpenCASCADE_INCLUDE_DIR})
    find_package(JPEG REQUIRED)
    find_package(draco REQUIRED)
endif()

set(OCCT_LIBS
    TKXDESTEP
    TKSTEP
    TKSTEP209
    TKSTEPAttr
    TKSTEPBase
    TKXCAF
    TKXSBase
    TKVCAF
    TKCAF
    TKLCAF
    TKCDF
    TKV3d
    TKService
    TKMesh
    TKBO
    TKPrim
    TKHLR
    TKShHealing
    TKTopAlgo
    TKGeomAlgo
    TKBRep
    TKGeomBase
    TKG3d
    TKG2d
    TKMath
    TKernel
)

# opencv_world is only available on non-WASM builds (dep_OpenCV is excluded from the WASM dep list)
if (TARGET opencv_world)
    target_link_libraries(libslic3r PUBLIC opencv_world)
endif()

target_link_libraries(libslic3r
    PUBLIC
        admesh
        libigl
        libnest2d
        miniz
    PRIVATE
        ${CMAKE_DL_LIBS}
        ${_expat_libs}
        ${_nlopt_libs}
        ${_gmp_libs}
        boost_libs
        cereal::cereal
        clipper
        Clipper2
        eigen
        glu-libtess
        ${_libslic3r_cgal_lib}
        mcut
        noise::noise
        qhull
        qoi
        semver
        TBB::tbb
        TBB::tbbmalloc
        ZLIB::ZLIB
    )
if(NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    target_link_libraries(libslic3r PRIVATE
        opencv_world
        ${OCCT_LIBS}
        draco::draco
        JPEG::JPEG
    )
endif()

if(NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    target_link_libraries(libslic3r PRIVATE
        PNG::PNG
        OpenSSL::Crypto
    )
endif()

if (NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    target_link_libraries(libslic3r PRIVATE libslic3r_cgal)
endif ()

if(NOT WIN32)
    # Link freetype for text/font rendering
    target_link_libraries(libslic3r PRIVATE ${FREETYPE_LIBRARIES})
    # fontconfig is a native Linux system library; not available under WASM/Emscripten
    if (NOT APPLE AND NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
        target_link_libraries(libslic3r PRIVATE fontconfig)
    endif()
endif()

if (APPLE)
    find_library(FOUNDATION Foundation REQUIRED)
    find_library(MODELIO ModelIO REQUIRED)
    target_link_libraries(libslic3r PRIVATE ${FOUNDATION} ${MODELIO})
endif ()

if (TARGET OpenVDB::openvdb)
    target_link_libraries(libslic3r PRIVATE OpenVDB::openvdb)
endif()

if(WIN32)
    target_link_libraries(libslic3r PRIVATE Psapi.lib bcrypt.lib)
endif()

if(SLIC3R_PROFILE)
    target_link_libraries(libslic3r PRIVATE Shiny)
endif()

if (SLIC3R_PCH AND NOT SLIC3R_SYNTAXONLY)
    add_precompiled_header(libslic3r pchheader.hpp FORCEINCLUDE)
endif ()
