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
option(USE_SLIC3R_CONSOLE_LOG "Enable console logging in RelWithDebInfo builds" OFF)

# SolveSpace constraint solver (2D sketch solver backbone), built in deps/SLVS.
if (SLIC3R_CAD)
    find_package(SLVS REQUIRED)
endif ()

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
    BeltBrim.cpp
    BeltBrim.hpp
    BeltGCode.cpp
    BeltGCode.hpp
    BeltPurge.cpp
    BeltSliceStrategy.cpp
    BeltSliceStrategy.hpp
    BeltTransform.cpp
    BeltTransform.hpp
    Brim.cpp
    BrimEarsPoint.hpp
    Brim.hpp
    BuildVolume.cpp
    BuildVolume.hpp
    calib.cpp
    calib.hpp
    Circle.cpp
    Circle.hpp
    ClipperUtils.cpp
    ClipperUtils.hpp
    ClipperZUtils.cpp
    ClipperZUtils.hpp
    Color.cpp
    Color.hpp
    CommonDefs.hpp
    Config.cpp
    Config.hpp
    ConnectedBodies.cpp
    ConnectedBodies.hpp
    ContourZ.cpp
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
    ExclusionVolumeGeometry.cpp
    ExclusionVolumeGeometry.hpp
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
    Fill/FillSpiralInset.cpp
    Fill/FillSpiralInset.hpp
    Fill/FillConcentricInternal.cpp
    Fill/FillConcentricInternal.hpp
    Fill/FillCornerSmoothing.cpp
    Fill/FillCornerSmoothing.hpp
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
    Fill/AdaptiveInfillField.cpp
    Fill/AdaptiveInfillField.hpp
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
    FilamentMixer.cpp
    FilamentMixer.hpp
    FilamentMixerModel.hpp
    ColorDecomposeRecipe.cpp
    ColorDecomposeRecipe.hpp
    TexturePainting.hpp
    TexturePainting.cpp
    TextureToColor/TextureToColor.hpp
    TextureToColor/TextureToColor.cpp
    TextureToColor/ColorUtils.hpp
    TextureToColor/ColorUtils.cpp
    Flow.cpp
    Flow.hpp
    FlushVolCalc.cpp
    FlushVolCalc.hpp
    Format/3mf.cpp
    Format/3mf.hpp
    Format/AMF.cpp
    Format/AMF.hpp
    Format/AssembleList.cpp
    Format/AssembleList.hpp
    Format/DRC.cpp
    Format/DRC.hpp
    Format/bbs_3mf.cpp
    Format/bbs_3mf.hpp
    Format/ProjectStrategy.hpp
    format.hpp
    Format/OBJ.cpp
    Format/OBJ.hpp
    Format/AssimpImport.hpp
    Format/AssimpImport.cpp
    Format/ResourcePathUtils.hpp
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
    GCode/BeltBackTransform.cpp
    GCode/BeltBackTransform.hpp
    GCode/MachineFrameTransform.cpp
    GCode/MachineFrameTransform.hpp
    GCode/BeltKinematics.cpp
    GCode/BeltKinematics.hpp
    GCode/MachineKinematics.cpp
    GCode/MachineKinematics.hpp
    GCode/ConflictChecker.cpp
    GCode/ConflictChecker.hpp
    GCode/CoolingBuffer.cpp
    GCode/CoolingBuffer.hpp
    GCode/ExclusionVolumePathCheck.cpp
    GCode/ExclusionVolumePathCheck.hpp
    GCode/ExclusionVolumeTravelAvoidance.cpp
    GCode/ExclusionVolumeTravelAvoidance.hpp
    GCode/TimelapsePosPicker.cpp
    GCode/TimelapsePosPicker.hpp
    GCode.cpp
    GCode/ExtrusionProcessor.hpp
    GCode/FanMover.cpp
    GCode/FanMover.hpp
    GCode/GCodeProcessor.cpp
    GCode/GCodeProcessor.hpp
    GCode/GCodeStatistics.cpp
    GCode/GCodeStatistics.hpp
    GCode/ElegooGCodeProcessorHelper.cpp
    GCode.hpp
    GCode/PchipInterpolatorHelper.cpp
    GCode/PchipInterpolatorHelper.hpp
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
    GCode/SeamContour.cpp
    GCode/SeamContour.hpp
    GCode/PreciseSeam.cpp
    GCode/PreciseSeam.hpp
    GCode/PreciseSeamInternal.hpp
    GCode/SmallAreaInfillFlowCompensator.cpp
    GCode/SmallAreaInfillFlowCompensator.hpp
    GCode/SpiralVase.cpp
    GCode/SpiralVase.hpp
    GCode/WipePathHelpers.cpp
    GCode/WipePathHelpers.hpp
    GCode/ThumbnailData.cpp
    GCode/ThumbnailData.hpp
    GCode/Thumbnails.cpp
    GCode/Thumbnails.hpp
    GCode/ToolOrdering.cpp
    GCode/ToolOrdering.hpp
    GCode/OrderingStrategies.cpp
    GCode/OrderingStrategies.hpp
    GCode/WipeTower2.cpp
    GCode/WipeTower2.hpp
    GCode/WipeTower.cpp
    GCode/WipeTower.hpp
    GCode/WipeTowerEstimate.cpp
    GCode/WipeTowerEstimate.hpp
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
    IMEXArrange.cpp
    IMEXArrange.hpp
    IMEXHelpers.cpp
    IMEXHelpers.hpp
    IMEXZones.cpp
    IMEXZones.hpp
    InstanceLock.cpp
    InstanceLock.hpp
    Int128.hpp
    KDTreeIndirect.hpp
    Layer.cpp
    Layer.hpp
    LayerRegion.cpp
    LayOnFace.cpp
    LayOnFace.hpp
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
    ParallelResolve.hpp
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
    PrinterBedAssets.hpp
    PresetCacheFormat.cpp
    PresetCacheFormat.hpp
    Preset.cpp
    Preset.hpp
    PrincipalComponents2D.cpp
    PrincipalComponents2D.hpp
    PublishSettings.cpp
    PublishSettings.hpp
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
    SLA/SupportTreeMesher.cpp
    SLA/SupportTreeMesher.hpp
    SlicesToTriangleMesh.cpp
    SlicesToTriangleMesh.hpp
    SlicingAdaptive.cpp
    SlicingAdaptive.hpp
    Slicing.cpp
    Slicing.hpp
    Support/BeltFloorContext.cpp
    Support/BeltFloorContext.hpp
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
    TextureDisplacement.cpp
    TextureDisplacement.hpp
    TextureBake/TextureBakeIndex.cpp
    TextureBake/TextureBakeIndex.hpp
    TextureBake/TextureBakeSubdivide.cpp
    TextureBake/TextureBakeSubdivide.hpp
    TextureBake/TextureBakeRegularize.cpp
    TextureBake/TextureBakeRegularize.hpp
    TextureBake/TextureBakeRelocate.cpp
    TextureBake/TextureBakeRelocate.hpp
    TextureBake/TextureBakeFlip.cpp
    TextureBake/TextureBakeFlip.hpp
    TextureBake/TextureBakeDebug.cpp
    TextureBake/TextureBakeDebug.hpp
    TextureBake/TextureBakeDisplace.cpp
    TextureBake/TextureBakeDisplace.hpp
    TextureBake/TextureBakeDecimate.cpp
    TextureBake/TextureBakeDecimate.hpp
    TextureBake/TextureBakeRepair.cpp
    TextureBake/TextureBakeRepair.hpp
    TextureBake/TextureBakePipeline.cpp
    TextureBake/TextureBakePipeline.hpp
    TextureBake/TextureBakeMesh.cpp
    TextureBake/TextureBakeMesh.hpp
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
    MultiNozzleUtils.hpp
    MultiNozzleUtils.cpp
    GCode/ToolOrderUtils.hpp
    GCode/ToolOrderUtils.cpp
    FlushVolPredictor.hpp
    FlushVolPredictor.cpp
)

# Parametric Design/CAD kernel. Needs OCCT's ModelingAlgorithms module and the
# vendored SolveSpace solver; both are pulled in only when SLIC3R_CAD is ON.
if (SLIC3R_CAD)
    list(APPEND lisbslic3r_sources
            CAD/GeometryEngine.cpp
            CAD/GeometryEngine.hpp
            CAD/SketchEngine.cpp
            CAD/SketchEngine.hpp
            CAD/SketchConstraints.cpp
            CAD/SketchConstraints.hpp
            CAD/SketchSolver.cpp
            CAD/SketchSolver.hpp
            CAD/SketchInference.cpp
            CAD/SketchInference.hpp
            CAD/SketchImport.cpp
            CAD/SketchImport.hpp
            CAD/CadDocument.cpp
            CAD/CadDocument.hpp
            CAD/ThreadStandards.cpp
            CAD/ThreadStandards.hpp
        )
endif ()

# Headless builds exclude SLA/resin features and GUI-only dependencies.
if (SLIC3R_HEADLESS)
    list(REMOVE_ITEM lisbslic3r_sources
        Geometry/VoronoiUtilsCgal.cpp
        Geometry/VoronoiUtilsCgal.hpp
        ObjColorUtils.cpp
        ObjColorUtils.hpp
        TexturePainting.cpp
        TexturePainting.hpp
        TextureToColor/TextureToColor.cpp
        TextureToColor/ColorUtils.cpp
        Format/SL1.cpp
        Format/SL1.hpp
        Format/DRC.cpp
        Format/DRC.hpp
        Format/AssimpImport.cpp
        Format/AssimpImport.hpp
        Shape/TextShape.cpp
        Shape/TextShape.hpp
        SLA/Clustering.cpp
        SLA/Clustering.hpp
        SLA/ConcaveHull.cpp
        SLA/ConcaveHull.hpp
        SLA/Hollowing.cpp
        SLA/Hollowing.hpp
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
    find_package(PNG REQUIRED)
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
# CGAL's config resets policies (cmake_minimum_required ...3.31), so a plain SET
# can't reach it; the default opts its Boost lookup into BoostConfig (CMP0167).
set(CMAKE_POLICY_DEFAULT_CMP0167 NEW)
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
    find_package(CGAL 6.2 REQUIRED)
endif ()
if (NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    find_package(OpenCV REQUIRED core)
    find_package(assimp REQUIRED)
endif ()
unset(CMAKE_POLICY_DEFAULT_CMP0167)
cmake_policy(POP)

if (NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    add_library(libslic3r_cgal STATIC 
        CutSurface.hpp CutSurface.cpp
        IntersectionPoints.hpp IntersectionPoints.cpp
        MeshBoolean.hpp MeshBoolean.cpp
        MeshRepair.hpp MeshRepair.cpp
        TryCatchSignal.hpp TryCatchSignal.cpp
        Triangulation.hpp Triangulation.cpp
    )
    target_include_directories(libslic3r_cgal PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
    get_target_property(_cgal_tgt CGAL::CGAL ALIASED_TARGET)
    if (NOT TARGET ${_cgal_tgt})
        set (_cgal_tgt CGAL::CGAL)
    endif ()
    if (IS_CLANG_CL)
        target_compile_options(libslic3r_cgal PRIVATE -Wno-overriding-option)
    endif()
    target_compile_definitions(libslic3r_cgal PRIVATE CGAL_LINKED_WITH_TBB)
    target_link_libraries(libslic3r_cgal PRIVATE ${_cgal_tgt} admesh libigl mcut boost_libs TBB::tbb)
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
# CGAL changes Kd_tree's member layout when TBB is enabled. Match libslic3r_cgal
# in every consumer so inline constructors/destructors cannot mix the two layouts.
target_compile_definitions(libslic3r PUBLIC CGAL_LINKED_WITH_TBB)
if (USE_SLIC3R_CONSOLE_LOG)
    target_compile_definitions(libslic3r PRIVATE $<$<CONFIG:RelWithDebInfo>:SLIC3R_CONSOLE_LOG>)
endif()
target_include_directories(libslic3r PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/TextureToColor PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
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
    find_package(Draco REQUIRED)
endif()

set(OCCT_LIBS
    TKDESTEP
    TKDE
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
# The CAD kernel is the only consumer of OCCT's ModelingAlgorithms module: TKFillet
# (BRepFilletAPI), TKOffset (BRepOffsetAPI) and TKBool, which the other two need.
#
# PREPEND, never append: this list is single-pass static link order, dependents before
# dependencies — note TKernel, which everything needs, is deliberately last. TKOffset
# references BRepAlgo_Loop, which TKBool defines, so TKOffset must come BEFORE TKBool.
# Appending put it after, and a strictly single-pass linker (the Flatpak build) failed with
#     libTKOffset.a(BRepOffset_MakeLoops.cxx.o): undefined reference to
#     `BRepAlgo_Loop::BRepAlgo_Loop()'
# while the ordinary Linux, macOS and Windows links resolved it anyway. Use set() rather
# than list(PREPEND), which needs CMake 3.15 and this project supports 3.13.
if (SLIC3R_CAD AND NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    set(OCCT_LIBS TKFillet TKOffset TKBool ${OCCT_LIBS})
    # deps is configured separately, so its SLIC3R_CAD can differ from ours. The module is
    # all-or-nothing, so one absent toolkit proves it; fail here rather than at link time.
    if (NOT TARGET TKFillet)
        message(FATAL_ERROR
            "SLIC3R_CAD is ON, but the OpenCASCADE in ${CMAKE_PREFIX_PATH} was built without "
            "BUILD_MODULE_ModelingAlgorithms. Rebuild the dependencies with -DSLIC3R_CAD=ON, "
            "or configure this project with -DSLIC3R_CAD=OFF.")
    endif ()
endif ()
# Published for the Windows packaging step in the top-level CMakeLists.txt.
set(OCCT_LIBS "${OCCT_LIBS}" CACHE INTERNAL "OCCT toolkits linked by libslic3r")
if (WIN32)
    # OCCT installs RelWithDebInfo and Debug builds to bin/occti and bin/occtd, so each build
    # type's DLL directory is read from the imported target, falling back to the first installed
    # build, as CMake does when linking.
    get_target_property(_occt_configs TKernel IMPORTED_CONFIGURATIONS)
    list(GET _occt_configs 0 _occt_fallback)
    foreach (_build_config IN ITEMS DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
        set(_occt_config ${_occt_fallback})
        if (_build_config IN_LIST _occt_configs)
            set(_occt_config ${_build_config})
        endif ()
        get_target_property(_occt_dll TKernel IMPORTED_LOCATION_${_occt_config})
        get_filename_component(_occt_bin "${_occt_dll}" DIRECTORY)
        set(OCCT_BIN_DIR_${_build_config} "${_occt_bin}" CACHE INTERNAL "OCCT DLL directory for ${_build_config} builds")
    endforeach ()
endif ()

# opencv_world is only available on non-WASM builds (dep_OpenCV is excluded from the WASM dep list)
if (TARGET opencv_world)
    target_link_libraries(libslic3r PUBLIC opencv_world)
endif()

target_link_libraries(libslic3r
    PUBLIC
        Eigen3::Eigen
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
        Clipper2
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
        assimp::assimp
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

if (SLIC3R_HEADLESS)
    target_link_libraries(libslic3r PRIVATE PNG::PNG)
endif()

if (NOT EMSCRIPTEN AND NOT SLIC3R_HEADLESS)
    target_link_libraries(libslic3r PRIVATE libslic3r_cgal)
endif ()

if (APPLE)
    find_library(FOUNDATION Foundation REQUIRED)
    find_library(MODELIO ModelIO REQUIRED)
    target_link_libraries(libslic3r PRIVATE ${FOUNDATION} ${MODELIO})
endif ()

if (TARGET OpenVDB::openvdb)
    target_link_libraries(libslic3r PRIVATE OpenVDB::openvdb)
endif()

if (SLIC3R_CAD)
    target_link_libraries(libslic3r PUBLIC SLVS::slvs)
endif ()

if(WIN32)
    target_link_libraries(libslic3r PRIVATE Psapi.lib bcrypt.lib)
endif()

if(SLIC3R_PROFILE)
    target_link_libraries(libslic3r PRIVATE Shiny)
endif()

if (WIN32)
    # Public, since BlacklistedLibraryCheck.hpp includes windows.h. Empty
    # WIN32_LEAN_AND_MEAN matches the sources that define it themselves; bare
    # NOMINMAX matches the one libigl already passes.
    target_compile_definitions(libslic3r PUBLIC "WIN32_LEAN_AND_MEAN=" "NOMINMAX")
endif ()

if (SLIC3R_PCH AND NOT SLIC3R_SYNTAXONLY)
    add_precompiled_header(libslic3r pchheader.hpp FORCEINCLUDE)
endif ()
