
set(_context_abi_line "")
set(_context_arch_line "")
if (APPLE AND CMAKE_OSX_ARCHITECTURES)
    if (CMAKE_OSX_ARCHITECTURES MATCHES "x86")
        set(_context_abi_line "-DBOOST_CONTEXT_ABI:STRING=sysv")
    elseif (CMAKE_OSX_ARCHITECTURES MATCHES "arm")
        set (_context_abi_line "-DBOOST_CONTEXT_ABI:STRING=aapcs")
    endif ()
    set(_context_arch_line "-DBOOST_CONTEXT_ARCHITECTURE:STRING=${CMAKE_OSX_ARCHITECTURES}")
endif ()

#pwd && cp ${CMAKE_CURRENT_LIST_DIR}/project-config.jam ./ &&
set(_boost_libraries, "--with-system --with-filesystem --with-log --with-locale --with-regex --with-chrono --with-atomic --with-date_time --with-iostreams --with-nowide")
set(_boost_settings, "--with-toolset=emscripten toolset=emscripten --threading=single address-model=32  ")

if (EMSCRIPTEN)
    set(_boost_emscripten_flags "${DEP_EMSCRIPT_CXX_FLAGS_RELEASE} -Wno-unused-private-field -Wno-missing-template-arg-list-after-template-kw")

    # Write a patch script at configure time to avoid CMake/shell quoting hell.
    # The semicolon in the jam file cannot safely be passed through /bin/sh -c "..."
    # when CMake is also processing the string.
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/boost_patch.sh"
"#!/bin/sh\n"
"set -e\n"
"mkdir -p tools/build/v2\n"
"printf 'using gcc : : em++ ;\\n' > tools/build/v2/user-config.jam\n"
"chmod +x bootstrap.sh\n"
"[ -f tools/build/src/engine/build.sh ] && chmod +x tools/build/src/engine/build.sh || true\n"
    )

    # Emscripten-specific configuration
    ExternalProject_Add(dep_Boost
        URL https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.zip
        URL_HASH SHA256=03530dec778bc1b85b070f0b077f3b01fd417133509bb19fe7c142e47777a87b
        INSTALL_DIR          ${DESTDIR}
        DOWNLOAD_DIR         ${DEP_DOWNLOAD_DIR}/${projectname}
        
        BUILD_IN_SOURCE     true
        CONFIGURE_COMMAND  emconfigure ./bootstrap.sh threading=multi address-model=32
        BUILD_COMMAND  env CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS_${_build_type_upper}} ${_boost_emscripten_flags}" emmake ./b2 cxxflags=${_boost_emscripten_flags} cxxflags=-DPTHREADS cxxflags=-DBOOST_THREAD_POSIX cxxflags=-DTHREAD linkflags=${DEP_EMSCRIPT_CXX_FLAGS_RELEASE} link=static toolset=emscripten threading=multi address-model=32 thread system filesystem regex chrono log atomic nowide iostreams random program_options --with-system --with-filesystem --with-locale --with-regex --with-chrono --with-atomic --with-date_time --with-iostreams --with-thread --with-log --with-nowide --with-program_options
        PATCH_COMMAND  /bin/sh "${CMAKE_CURRENT_BINARY_DIR}/boost_patch.sh"
        INSTALL_COMMAND env CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS_${_build_type_upper}} ${_boost_emscripten_flags}" emmake ./b2 cxxflags=${_boost_emscripten_flags} cxxflags=-DPTHREADS cxxflags=-DBOOST_THREAD_POSIX cxxflags=-DTHREAD install linkflags=${DEP_EMSCRIPT_CXX_FLAGS_RELEASE} link=static toolset=emscripten threading=multi address-model=32 --prefix=${DESTDIR} system filesystem regex chrono iostreams random atomic nowide thread log program_options --with-log --with-system --with-filesystem --with-locale --with-regex --with-chrono --with-atomic --with-date_time --with-iostreams --with-thread --with-nowide --with-program_options
        CMAKE_ARGS
            -DBOOST_EXCLUDE_LIBRARIES:STRING=contract|fiber|numpy|stacktrace|wave|test
            -DBOOST_LOCALE_ENABLE_ICU:BOOL=OFF
            -DBUILD_TESTING:BOOL=OFF
            -DBOOST_IOSTREAMS_ENABLE_ZSTD:BOOL=OFF
            "${_context_abi_line}"
            "${_context_arch_line}"
            -DCMAKE_INSTALL_PREFIX:STRING=${DESTDIR}
            -DCMAKE_MODULE_PATH:STRING=${PROJECT_SOURCE_DIR}/../cmake/modules
            -DCMAKE_PREFIX_PATH:STRING=${DESTDIR}
            -DCMAKE_DEBUG_POSTFIX:STRING=d
            -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
            -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
            -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE}
            -DBUILD_SHARED_LIBS:BOOL=OFF
            -DCMAKE_CXX_FLAGS_${_build_type_upper}:STRING="${CMAKE_CXX_FLAGS_${_build_type_upper}} -pthread -pthreads -Wno-unused-private-field -Wno-missing-template-arg-list-after-template-kw"
            -DCMAKE_C_FLAGS_${_build_type_upper}:STRING="${CMAKE_C_FLAGS_${_build_type_upper}} -pthread -pthreads -Wno-unused-private-field -Wno-missing-template-arg-list-after-template-kw"
            -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE}
            -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
    )
else()
    # Native build (Linux, macOS, etc.) - use standard CMake build
    ExternalProject_Add(dep_Boost
        URL https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.zip
        URL_HASH SHA256=03530dec778bc1b85b070f0b077f3b01fd417133509bb19fe7c142e47777a87b
        INSTALL_DIR          ${DESTDIR}
        DOWNLOAD_DIR         ${DEP_DOWNLOAD_DIR}/${projectname}
        CMAKE_ARGS
            -DBOOST_EXCLUDE_LIBRARIES:STRING=contract|fiber|numpy|stacktrace|wave|test
            -DBOOST_LOCALE_ENABLE_ICU:BOOL=OFF
            -DBUILD_TESTING:BOOL=OFF
            -DBOOST_IOSTREAMS_ENABLE_ZSTD:BOOL=OFF
            "${_context_abi_line}"
            "${_context_arch_line}"
            -DCMAKE_INSTALL_PREFIX:STRING=${DESTDIR}
            -DCMAKE_MODULE_PATH:STRING=${PROJECT_SOURCE_DIR}/../cmake/modules
            -DCMAKE_PREFIX_PATH:STRING=${DESTDIR}
            -DCMAKE_DEBUG_POSTFIX:STRING=d
            -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}
            -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}
            -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE}
            -DBUILD_SHARED_LIBS:BOOL=OFF
            -DCMAKE_CXX_FLAGS_${_build_type_upper}:STRING="${CMAKE_CXX_FLAGS_${_build_type_upper}} -pthread"
            -DCMAKE_C_FLAGS_${_build_type_upper}:STRING="${CMAKE_C_FLAGS_${_build_type_upper}} -pthread"
            -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
    )
endif()

set(DEP_Boost_DEPENDS ZLIB)
