#!/bin/bash

set -e -x

source $CI_SCRIPTS/epics-config.sh

[ -z "$EPICS_BASE" ] && echo "EPICS_BASE unset" && exit 1;
[ -z "$SUPPORT" ] && echo "SUPPORT unset" && exit 1;
[ -z "$BUILD_ROOT" ] && echo "BUILD_ROOT unset" && exit 1;

fix_areadetector() {
    # Grab additional submodule releases
    if [ ! -d ADCore/configure ]; then
        download_and_extract "https://github.com/areaDetector/ADCore/archive/R${AREADETECTOR}.tar.gz" ADCore
    fi

    # TODO: hard-coded ADSimDetector 2.7
    if [ ! -d ADSimDetector/configure ]; then
        download_and_extract "https://github.com/areaDetector/ADSimDetector/archive/R2-7.tar.gz" ADSimDetector
    fi
    
    chmod a+rw configure/*

    # RELEASE
    # Restore the original release file (installed by our bash scripts)
    cat > configure/RELEASE <<'EOF'
-include $(TOP)/../configure/RELEASE_LIBS_INCLUDE
-include $(TOP)/RELEASE.local
-include $(TOP)/configure/RELEASE.local
EOF
    cat configure/RELEASE
    
    # RELEASE_PATHS.local
    cat > configure/RELEASE_PATHS.local <<EOF
SUPPORT=$SUPPORT
AREA_DETECTOR=${AREA_DETECTOR_PATH}
ADSUPPORT=${AREA_DETECTOR_PATH}/ADSupport
ADCORE=${AREA_DETECTOR_PATH}/ADCore
ADSIMDETECTOR=${AREA_DETECTOR_PATH}/ADSimDetector
EPICS_BASE=$EPICS_BASE
EOF

    # RELEASE_LIBS.local
    cat > configure/RELEASE_LIBS.local <<EOF
# INSTALL_LOCATION_APP=${AREA_DETECTOR_PATH}
ASYN=${ASYN_PATH}
ADSUPPORT=${AREA_DETECTOR_PATH}/ADSupport
ADCORE=${AREA_DETECTOR_PATH}/ADCore
EOF
    
    if [[ ! -z "${PVA}" ]]; then 
        cat >> configure/RELEASE_LIBS.local <<EOF
PVACCESS=${PVA_PATH}/pvAccess
PVDATA=${PVA_PATH}/pvData
PVDATABASE=${PVA_PATH}/pvDatabase
NORMATIVETYPES=${PVA_PATH}/normativeTypes
EOF
    fi

    cat >> configure/RELEASE_LIBS.local <<'EOF'
-include $(AREA_DETECTOR)/configure/RELEASE_LIBS.local.$(EPICS_HOST_ARCH)
EOF
    
    cat configure/RELEASE_LIBS.local
    
    # RELEASE.local
    cat > configure/RELEASE.local <<EOF
AREA_DETECTOR=${AREA_DETECTOR_PATH}
ADSUPPORT=${AREA_DETECTOR_PATH}/ADSupport
ADCORE=${AREA_DETECTOR_PATH}/ADCore
ADSIMDETECTOR=${AREA_DETECTOR_PATH}/ADSimDetector
-include \$(AREA_DETECTOR)/configure/RELEASE.local.\$(EPICS_HOST_ARCH)
EOF

    cat configure/RELEASE.local

    # RELEASE_PRODS.local
    cat > configure/RELEASE_PRODS.local <<EOF
    include \$(TOP)/configure/RELEASE_LIBS.local
AUTOSAVE=${AUTOSAVE_PATH}
BUSY=${BUSY_PATH}
CALC=${CALC_PATH}
SNCSEQ=${SNCSEQ_PATH}
SSCAN=${SSCAN_PATH}
EOF

    cat configure/RELEASE_PRODS.local

    # CONFIG_SITE.arch.Common
    cat > configure/CONFIG_SITE.$EPICS_HOST_ARCH.Common <<EOF
WITH_BOOST=NO
BOOST_EXTERNAL=NO
WITH_HDF5=YES
HDF5_EXTERNAL=NO
XML2_EXTERNAL=NO
WITH_NETCDF=YES
NETCDF_EXTERNAL=NO
WITH_NEXUS=YES
NEXUS_EXTERNAL=NO
WITH_TIFF=YES
TIFF_EXTERNAL=NO
WITH_JPEG=YES
JPEG_EXTERNAL=NO
WITH_SZIP=YES
SZIP_EXTERNAL=NO
WITH_ZLIB=YES
ZLIB_EXTERNAL=NO
HOST_OPT=NO
WITH_PVA=${WITH_PVA}
EOF

    # Install ADSupport
    if [ ! -d ADSupport/configure ]; then
        git clone --depth=1 --branch=master https://github.com/areaDetector/ADSupport.git
    fi

    # ADSupport/RELEASE.arch.Common
    echo "EPICS_BASE=$EPICS_BASE" > ADSupport/configure/RELEASE.$EPICS_HOST_ARCH.Common

    # Copy the same config site file generated above for ADSupport
    # ADSupport/CONFIG_SITE.arch.Common
    cp configure/CONFIG_SITE.$EPICS_HOST_ARCH.Common ADSupport/configure
    # make -C ADSupport
}

# areadetector
install_from_github_archive \
    "https://github.com/areaDetector/areaDetector/archive/R${AREADETECTOR}.tar.gz" \
    "areadetector" "${AREA_DETECTOR_PATH}" "${AREA_DETECTOR_PATH}" \
    fix_areadetector
