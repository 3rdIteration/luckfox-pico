#!/bin/bash
# GCC 11.2 Toolchain Download and Installation Script
# This script downloads and sets up the ARM GCC 11.2 toolchain for Luckfox Pico SDK
# Official support: https://wiki.luckfox.com/Luckfox-Pico-Plus-Mini/Cross-Compile/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="${SCRIPT_DIR}"
TOOLCHAIN_NAME="gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf"
TOOLCHAIN_ARCHIVE="${TOOLCHAIN_NAME}.tar.xz"

# Multiple download sources (try in order)
DOWNLOAD_SOURCES=(
    "https://files.luckfox.com/toolchain/${TOOLCHAIN_ARCHIVE}"
    "https://developer.arm.com/-/media/Files/downloads/gnu-a/11.2-2022.02/binrel/${TOOLCHAIN_ARCHIVE}"
    "https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/11.2-2022.02/binrel/${TOOLCHAIN_ARCHIVE}"
)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GCC 11.2 Toolchain Installation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if toolchain already exists
if [ -d "${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}" ]; then
    echo -e "${YELLOW}GCC 11.2 toolchain already exists at:${NC}"
    echo "  ${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}"
    echo ""
    
    # Verify it's working
    if [ -x "${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}/bin/arm-none-linux-gnueabihf-gcc" ]; then
        GCC_VERSION=$(${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}/bin/arm-none-linux-gnueabihf-gcc --version | head -n1)
        echo -e "${GREEN}✓ Toolchain is installed and functional:${NC}"
        echo "  ${GCC_VERSION}"
        echo ""
        echo -e "${YELLOW}To use this toolchain, run:${NC}"
        echo "  cd ${SCRIPT_DIR}"
        echo "  ./switch_gcc_version.sh 11"
        echo ""
        echo "Or manually update your defconfig files."
        echo "See docs/GCC_VERSION_CONFIGURATION.md for complete instructions"
        exit 0
    else
        echo -e "${RED}✗ Toolchain directory exists but GCC binary not found or not executable${NC}"
        echo "  Removing incomplete installation..."
        rm -rf "${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}"
    fi
fi

# Check available disk space (need ~500MB)
AVAILABLE_SPACE=$(df -BM "${TOOLCHAIN_DIR}" | awk 'NR==2 {print $4}' | sed 's/M//')
if [ "${AVAILABLE_SPACE}" -lt 500 ]; then
    echo -e "${RED}✗ Insufficient disk space${NC}"
    echo "  Required: ~500MB"
    echo "  Available: ${AVAILABLE_SPACE}MB"
    exit 1
fi

# Download toolchain - try each source until one works
echo -e "${GREEN}Downloading GCC 11.2 ARM toolchain...${NC}"
echo "  Size: ~100MB (expands to ~400MB)"
echo ""

DOWNLOAD_SUCCESS=0

if [ -f "${TOOLCHAIN_DIR}/${TOOLCHAIN_ARCHIVE}" ]; then
    echo -e "${YELLOW}Archive already downloaded, skipping download${NC}"
    DOWNLOAD_SUCCESS=1
else
    # Check if wget or curl is available
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        echo -e "${RED}✗ Neither wget nor curl found${NC}"
        echo "  Please install wget or curl and try again"
        exit 1
    fi
    
    # Try each download source
    for url in "${DOWNLOAD_SOURCES[@]}"; do
        echo -e "${YELLOW}Trying: ${url}${NC}"
        
        if command -v wget &> /dev/null; then
            if wget --timeout=10 --tries=2 --show-progress -O "${TOOLCHAIN_DIR}/${TOOLCHAIN_ARCHIVE}" "${url}" 2>&1; then
                DOWNLOAD_SUCCESS=1
                break
            fi
        elif command -v curl &> /dev/null; then
            if curl --connect-timeout 10 --retry 2 -L --progress-bar -o "${TOOLCHAIN_DIR}/${TOOLCHAIN_ARCHIVE}" "${url}" 2>&1; then
                DOWNLOAD_SUCCESS=1
                break
            fi
        fi
        
        # Clean up failed download
        rm -f "${TOOLCHAIN_DIR}/${TOOLCHAIN_ARCHIVE}"
        echo -e "${YELLOW}  Failed, trying next source...${NC}"
    done
fi

if [ ${DOWNLOAD_SUCCESS} -eq 0 ]; then
    echo ""
    echo -e "${RED}✗ All download sources failed${NC}"
    echo ""
    echo "Please download manually:"
    echo "1. Download from: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
    echo "   (Look for: gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz)"
    echo ""
    echo "2. Or try Luckfox mirror:"
    echo "   https://files.luckfox.com/toolchain/${TOOLCHAIN_ARCHIVE}"
    echo ""
    echo "3. Place the file in: ${TOOLCHAIN_DIR}/"
    echo ""
    echo "4. Run this script again"
    exit 1
fi

# Extract toolchain
echo ""
echo -e "${GREEN}Extracting toolchain...${NC}"
tar -xf "${TOOLCHAIN_DIR}/${TOOLCHAIN_ARCHIVE}" -C "${TOOLCHAIN_DIR}" || {
    echo -e "${RED}✗ Extraction failed${NC}"
    exit 1
}

# Verify installation
if [ ! -x "${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}/bin/arm-none-linux-gnueabihf-gcc" ]; then
    echo -e "${RED}✗ Installation verification failed${NC}"
    echo "  GCC binary not found or not executable"
    exit 1
fi

# Test the compiler
GCC_VERSION=$(${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}/bin/arm-none-linux-gnueabihf-gcc --version | head -n1)

# Cleanup archive (optional, comment out to keep)
echo ""
echo -e "${GREEN}Cleaning up archive...${NC}"
rm -f "${TOOLCHAIN_DIR}/${TOOLCHAIN_ARCHIVE}"

# Success message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installed: ${GCC_VERSION}"
echo "Location:  ${TOOLCHAIN_DIR}/${TOOLCHAIN_NAME}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Switch to GCC 11.2 (automatic configuration):"
echo "   cd ${SCRIPT_DIR}"
echo "   ./switch_gcc_version.sh 11"
echo ""
echo "2. Clean and rebuild:"
echo "   cd ${SCRIPT_DIR}/../../../.."
echo "   ./build.sh clean"
echo "   ./build.sh lunch"
echo "   ./build.sh all"
echo ""
echo "For complete instructions and manual configuration:"
echo "   See docs/GCC_VERSION_CONFIGURATION.md"
echo ""
