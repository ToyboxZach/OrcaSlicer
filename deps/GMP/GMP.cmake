
set(_srcdir ${CMAKE_CURRENT_LIST_DIR}/gmp)

if (IN_GIT_REPO)
    set(GMP_DIRECTORY_FLAG --directory ${BINARY_DIR_REL}/dep_GMP-prefix/src/dep_GMP)
endif ()

if (MSVC)
    set(_output  ${DESTDIR}/include/gmp.h
                 ${DESTDIR}/lib/libgmp-10.lib
                 ${DESTDIR}/bin/libgmp-10.dll)

    add_custom_command(
        OUTPUT  ${_output}
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/include/gmp.h ${DESTDIR}/include/
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/lib/win-${DEPS_ARCH}/libgmp-10.lib ${DESTDIR}/lib/
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/lib/win-${DEPS_ARCH}/libgmp-10.dll ${DESTDIR}/bin/
    )

    add_custom_target(dep_GMP SOURCES ${_output})

else ()
    set(_gmp_ccflags "-O2 -DNDEBUG -fPIC -DPIC -Wall -Wmissing-prototypes -Wpointer-arith -pedantic -fomit-frame-pointer -fno-common")
    set(_gmp_build_tgt "${CMAKE_SYSTEM_PROCESSOR}")

    if (APPLE)
        if (${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm")
            set(_gmp_build_arch aarch64)
        else ()
            set(_gmp_build_arch ${CMAKE_SYSTEM_PROCESSOR})
        endif()
        if (IS_CROSS_COMPILE)
            if (${CMAKE_OSX_ARCHITECTURES} MATCHES "arm")
                set(_gmp_host_arch aarch64)
                set(_gmp_host_arch_flags "-arch arm64")
            elseif (${CMAKE_OSX_ARCHITECTURES} MATCHES "x86_64")
                set(_gmp_host_arch x86_64)
                set(_gmp_host_arch_flags "-arch x86_64")
            endif()
            set(_gmp_ccflags "${_gmp_ccflags} ${_gmp_host_arch_flags} -mmacosx-version-min=${DEP_OSX_TARGET}")
            set(_gmp_build_tgt --build=${_gmp_build_arch}-apple-darwin --host=${_gmp_host_arch}-apple-darwin)
        else ()
            set(_gmp_ccflags "${_gmp_ccflags} -mmacosx-version-min=${DEP_OSX_TARGET}")
            set(_gmp_build_tgt "--build=${_gmp_build_arch}-apple-darwin")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if (${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm")
            set(_gmp_ccflags "${_gmp_ccflags} -march=armv7-a -DNO_ASM") # Works on RPi-4
            set(_gmp_build_tgt armv7)
        endif()
        set(_gmp_build_tgt "--build=${_gmp_build_tgt}-pc-linux-gnu")
    else ()
        set(_gmp_build_tgt "") # let it guess
    endif()

    set(_cross_compile_arg "")
    if (CMAKE_CROSSCOMPILING)
        # TOOLCHAIN_PREFIX should be defined in the toolchain file
        set(_cross_compile_arg --host=${TOOLCHAIN_PREFIX})
    endif ()

    if (EMSCRIPTEN)
        # Use CMake-provided Emscripten flags which include -matomics -mbulk-memory
        string(APPEND _gmp_ccflags " ${DEP_EMSCRIPT_CXX_FLAGS_RELEASE}")
        string(APPEND _gmp_ccflags " -pthread -matomics -mbulk-memory")
        ExternalProject_Add(dep_GMP
            URL https://github.com/SoftFever/OrcaSlicer_deps/releases/download/gmp-6.2.1/gmp-6.2.1.tar.bz2
            URL_HASH SHA256=eae9326beb4158c386e39a356818031bd28f3124cf915f8c5b1dc4c7a36b4d7c
            DOWNLOAD_DIR ${DEP_DOWNLOAD_DIR}/GMP
            BUILD_IN_SOURCE ON 
            PATCH_COMMAND   echo "#! /bin/sh" > tmp && echo "unset HOST_CC" >> tmp &&  cat ./configure >> tmp && mv tmp ./configure && chmod +x ./configure 
            CONFIGURE_COMMAND env "CFLAGS=${_gmp_ccflags}" "CXXFLAGS=${_gmp_ccflags}" CC_FOR_BUILD=gcc emconfigure ./configure --enable-cxx --host=none  --enable-fft=yes  --enable-alloca=malloc-notreentrant --enable-shared=no --enable-static=yes   "--prefix=${DESTDIR}" ${_gmp_build_tgt}
            BUILD_COMMAND     MPN_PATH="generic" emmake make -j 
            INSTALL_COMMAND   emmake make  install 
            CMAKE_ARGS
                -DCMAKE_INSTALL_PREFIX:STRING=${${PROJECT_NAME}_DEP_INSTALL_PREFIX}
                -DCMAKE_MODULE_PATH:STRING=${CMAKE_MODULE_PATH}
                -DCMAKE_PREFIX_PATH:STRING=${${PROJECT_NAME}_DEP_INSTALL_PREFIX}
                -DCMAKE_DEBUG_POSTFIX:STRING=${CMAKE_DEBUG_POSTFIX}
                -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
                -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
                -DCMAKE_CXX_FLAGS_${_build_type_upper}:STRING=${CMAKE_CXX_FLAGS_${_build_type_upper}}
                -DCMAKE_C_FLAGS_${_build_type_upper}:STRING=${CMAKE_C_FLAGS_${_build_type_upper}}
                -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE}
                -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
                ${P_ARGS_CMAKE_ARGS}
        )
    else()
        ExternalProject_Add(dep_GMP
            URL https://github.com/SoftFever/OrcaSlicer_deps/releases/download/gmp-6.2.1/gmp-6.2.1.tar.bz2
            URL_HASH SHA256=eae9326beb4158c386e39a356818031bd28f3124cf915f8c5b1dc4c7a36b4d7c
            DOWNLOAD_DIR ${DEP_DOWNLOAD_DIR}/GMP
            BUILD_IN_SOURCE ON 
            PATCH_COMMAND   echo "#! /bin/sh" > tmp && echo "unset HOST_CC" >> tmp &&  cat ./configure >> tmp && mv tmp ./configure && chmod +x ./configure 
            CONFIGURE_COMMAND env "CFLAGS=${_gmp_ccflags}" "CXXFLAGS=${_gmp_ccflags}" CC_FOR_BUILD=gcc ./configure --enable-cxx --enable-fft=yes  --enable-alloca=malloc-notreentrant --enable-shared=no --enable-static=yes   "--prefix=${DESTDIR}"
            BUILD_COMMAND     MPN_PATH="generic" make -j 
            INSTALL_COMMAND   make  install 
            CMAKE_ARGS
                -DCMAKE_INSTALL_PREFIX:STRING=${${PROJECT_NAME}_DEP_INSTALL_PREFIX}
                -DCMAKE_MODULE_PATH:STRING=${CMAKE_MODULE_PATH}
                -DCMAKE_PREFIX_PATH:STRING=${${PROJECT_NAME}_DEP_INSTALL_PREFIX}
                -DCMAKE_DEBUG_POSTFIX:STRING=${CMAKE_DEBUG_POSTFIX}
                -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
                -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
                -DCMAKE_CXX_FLAGS_${_build_type_upper}:STRING=${CMAKE_CXX_FLAGS_${_build_type_upper}}
                -DCMAKE_C_FLAGS_${_build_type_upper}:STRING=${CMAKE_C_FLAGS_${_build_type_upper}}
                -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE}
                -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
                ${P_ARGS_CMAKE_ARGS}
        )
    endif()
endif ()
