#!/bin/bash
# Script to switch between GCC 8.3.0 (default) and GCC 11.2
# Usage: ./switch_gcc_version.sh [8|11]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="${SCRIPT_DIR}/../../../.."
DEFCONFIG_DIR="${SDK_ROOT}/sysdrv/tools/board/buildroot"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    echo "Usage: $0 [8|11]"
    echo ""
    echo "Switch between GCC versions for Luckfox Pico SDK:"
    echo "  8  - Switch to GCC 8.3.0 (default, included toolchain)"
    echo "  11 - Switch to GCC 11.2 (officially supported, requires installation)"
    echo ""
    echo "Examples:"
    echo "  $0 11    # Switch to GCC 11.2"
    echo "  $0 8     # Switch back to GCC 8.3.0"
    echo ""
}

update_defconfig() {
    local defconfig_file="$1"
    local gcc_version="$2"
    
    if [ ! -f "${defconfig_file}" ]; then
        echo -e "${RED}✗ Defconfig file not found: ${defconfig_file}${NC}"
        return 1
    fi
    
    if [ "${gcc_version}" = "11" ]; then
        # Switch to GCC 11.2
        local toolchain_name="gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
        local toolchain_prefix="arm-none-linux-gnueabihf"
        local toolchain_path="../../../../tools/linux/toolchain/${toolchain_name}"
        
        # Check if GCC 11.2 is installed
        if [ ! -d "${SCRIPT_DIR}/${toolchain_name}" ]; then
            echo -e "${RED}✗ GCC 11.2 toolchain not found${NC}"
            echo ""
            echo "Please install it first:"
            echo "  cd tools/linux/toolchain"
            echo "  ./install_gcc_11.2.sh"
            return 1
        fi
        
        # Update defconfig
        sed -i "s|BR2_TOOLCHAIN_EXTERNAL_PATH=.*|BR2_TOOLCHAIN_EXTERNAL_PATH=\"${toolchain_path}\"|" "${defconfig_file}"
        sed -i "s|BR2_TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX=.*|BR2_TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX=\"${toolchain_prefix}\"|" "${defconfig_file}"
        sed -i 's|BR2_TOOLCHAIN_EXTERNAL_GCC_8=y|BR2_TOOLCHAIN_EXTERNAL_GCC_11=y|' "${defconfig_file}"
        
        echo -e "${GREEN}✓ Updated to GCC 11.2${NC}"
        
    elif [ "${gcc_version}" = "8" ]; then
        # Switch back to GCC 8.3.0
        local toolchain_name="arm-rockchip830-linux-uclibcgnueabihf"
        local toolchain_prefix="arm-rockchip830-linux-uclibcgnueabihf"
        local toolchain_path="../../../../tools/linux/toolchain/${toolchain_name}"
        
        # Update defconfig
        sed -i "s|BR2_TOOLCHAIN_EXTERNAL_PATH=.*|BR2_TOOLCHAIN_EXTERNAL_PATH=\"${toolchain_path}\"|" "${defconfig_file}"
        sed -i "s|BR2_TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX=.*|BR2_TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX=\"${toolchain_prefix}\"|" "${defconfig_file}"
        sed -i 's|BR2_TOOLCHAIN_EXTERNAL_GCC_11=y|BR2_TOOLCHAIN_EXTERNAL_GCC_8=y|' "${defconfig_file}"
        
        echo -e "${GREEN}✓ Updated to GCC 8.3.0${NC}"
    fi
}

# Main script
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

GCC_VERSION="$1"

if [ "${GCC_VERSION}" != "8" ] && [ "${GCC_VERSION}" != "11" ]; then
    echo -e "${RED}✗ Invalid GCC version: ${GCC_VERSION}${NC}"
    echo ""
    show_usage
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GCC Version Switcher${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "${GCC_VERSION}" = "11" ]; then
    echo -e "${GREEN}Switching to GCC 11.2...${NC}"
else
    echo -e "${GREEN}Switching to GCC 8.3.0 (default)...${NC}"
fi
echo ""

# Update both defconfig files
echo "Updating luckfox_pico_defconfig..."
update_defconfig "${DEFCONFIG_DIR}/luckfox_pico_defconfig" "${GCC_VERSION}"

echo "Updating luckfox_pico_w_defconfig..."
update_defconfig "${DEFCONFIG_DIR}/luckfox_pico_w_defconfig" "${GCC_VERSION}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ GCC Version Switch Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "${GCC_VERSION}" = "11" ]; then
    GCC_PATH="${SCRIPT_DIR}/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
    if [ -x "${GCC_PATH}/bin/arm-none-linux-gnueabihf-gcc" ]; then
        GCC_INFO=$(${GCC_PATH}/bin/arm-none-linux-gnueabihf-gcc --version | head -n1)
        echo "Active toolchain: ${GCC_INFO}"
    fi
else
    GCC_PATH="${SCRIPT_DIR}/arm-rockchip830-linux-uclibcgnueabihf"
    if [ -x "${GCC_PATH}/bin/arm-rockchip830-linux-uclibcgnueabihf-gcc" ]; then
        GCC_INFO=$(${GCC_PATH}/bin/arm-rockchip830-linux-uclibcgnueabihf-gcc --version | head -n1)
        echo "Active toolchain: ${GCC_INFO}"
    fi
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Clean previous build:"
echo "   ./build.sh clean"
echo ""
echo "2. Configure and build:"
echo "   ./build.sh lunch"
echo "   ./build.sh all"
echo ""
