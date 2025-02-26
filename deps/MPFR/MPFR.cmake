set(_srcdir ${CMAKE_CURRENT_LIST_DIR}/mpfr)

if (MSVC)
    set(_output  ${DESTDIR}/include/mpfr.h
                 ${DESTDIR}/include/mpf2mpfr.h
                 ${DESTDIR}/lib/libmpfr-4.lib 
                 ${DESTDIR}/bin/libmpfr-4.dll)

    add_custom_command(
        OUTPUT  ${_output}
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/include/mpfr.h ${DESTDIR}/include/
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/include/mpf2mpfr.h ${DESTDIR}/include/
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/lib/win${DEPS_BITS}/libmpfr-4.lib ${DESTDIR}/lib/
        COMMAND ${CMAKE_COMMAND} -E copy ${_srcdir}/lib/win${DEPS_BITS}/libmpfr-4.dll ${DESTDIR}/bin/
    )

    add_custom_target(dep_MPFR SOURCES ${_output})

else ()

    # set(_cross_compile_arg "")
    # if (CMAKE_CROSSCOMPILING)
    #     # TOOLCHAIN_PREFIX should be defined in the toolchain file
    #     set(_cross_compile_arg --host=${TOOLCHAIN_PREFIX})
    # endif ()

    message(STATUS "${PROJECT_NAME}_DEP_INSTALL_PREFIX=${${PROJECT_NAME}_DEP_INSTALL_PREFIX}")

    ExternalProject_Add(dep_MPFR
        URL https://www.mpfr.org/mpfr-current/mpfr-4.2.1.tar.bz2
        URL_HASH SHA256=b9df93635b20e4089c29623b19420c4ac848a1b29df1cfd59f26cab0d2666aa0
        DOWNLOAD_DIR ${DEP_DOWNLOAD_DIR}/MPFR
        BUILD_IN_SOURCE ON
        CONFIGURE_COMMAND autoreconf -f -i && 
                          env "CFLAGS=${_gmp_ccflags}" "CXXFLAGS=${_gmp_ccflags}" CC_FOR_BUILD=gcc emconfigure ./configure ${_cross_compile_arg}  --prefix=${DESTDIR} --enable-shared=no --enable-static=yes --with-gmp=${DESTDIR} ${_gmp_build_tgt} --host none --enable-assert=none --disable-thread-safe --disable-float128 --disable-decimal-float --enable-gmp-internals  --enable-static=yes
        BUILD_COMMAND touch aclocal.m4 configure Makefile.am Makefile.in ./doc/Makefile.am ./doc/Makefile.in ./doc/mpfr.info && emmake make -j
        INSTALL_COMMAND make install
        DEPENDS dep_GMP
    )
endif ()

set(DEP_MPFR_DEPENDS GMP)
