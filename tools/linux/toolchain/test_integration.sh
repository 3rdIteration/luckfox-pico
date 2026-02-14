#!/bin/bash
# Local test script for GCC 11.2 integration
# This can be run locally to test the scripts without GitHub Actions

# Don't exit on error - we want to run all tests
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate up from tools/linux/toolchain to SDK root
SDK_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    local name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $name"
        TEST_RESULTS+=("PASS: $name")
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $name"
        TEST_RESULTS+=("FAIL: $name")
        ((TESTS_FAILED++))
    fi
}

echo -e "${BLUE}========================================"
echo "GCC 11.2 Integration Test Suite"
echo -e "========================================${NC}"
echo ""

# Test 1: Check scripts exist and are executable
echo -e "${YELLOW}Test 1: Script files${NC}"
if [ -x "${SDK_ROOT}/tools/linux/toolchain/install_gcc_11.2.sh" ] && \
   [ -x "${SDK_ROOT}/tools/linux/toolchain/switch_gcc_version.sh" ]; then
    log_test "Scripts exist and are executable" "PASS"
else
    log_test "Scripts exist and are executable" "FAIL"
fi

# Test 2: Switcher shows usage
echo -e "${YELLOW}Test 2: Switcher usage message${NC}"
cd "${SDK_ROOT}/tools/linux/toolchain"
if ./switch_gcc_version.sh 2>&1 | grep -q "Usage:"; then
    log_test "Switcher shows usage" "PASS"
else
    log_test "Switcher shows usage" "FAIL"
fi

# Test 3: Switcher rejects invalid argument
echo -e "${YELLOW}Test 3: Switcher input validation${NC}"
if ! ./switch_gcc_version.sh 99 >/dev/null 2>&1; then
    log_test "Switcher rejects invalid input" "PASS"
else
    log_test "Switcher rejects invalid input" "FAIL"
fi

# Test 4: Check if GCC 11.2 is already installed
echo -e "${YELLOW}Test 4: GCC 11.2 installation check${NC}"
GCC11_INSTALLED=0
if [ -d "${SDK_ROOT}/tools/linux/toolchain/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf" ]; then
    if [ -x "${SDK_ROOT}/tools/linux/toolchain/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-gcc" ]; then
        GCC11_INSTALLED=1
        GCC_VERSION=$(${SDK_ROOT}/tools/linux/toolchain/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/bin/arm-none-linux-gnueabihf-gcc --version | head -n1)
        echo "  Already installed: ${GCC_VERSION}"
        log_test "GCC 11.2 is installed" "PASS"
    else
        echo "  Directory exists but GCC binary not functional"
        log_test "GCC 11.2 installation" "FAIL"
    fi
else
    echo "  Not installed (run install_gcc_11.2.sh to install)"
    log_test "GCC 11.2 not installed (expected)" "PASS"
fi

# Test 5: Switch to GCC 11 (if installed)
if [ ${GCC11_INSTALLED} -eq 1 ]; then
    echo -e "${YELLOW}Test 5: Switch to GCC 11.2${NC}"
    
    # Backup current defconfig
    cp "${SDK_ROOT}/sysdrv/tools/board/buildroot/luckfox_pico_defconfig" \
       "/tmp/luckfox_pico_defconfig.backup"
    
    cd "${SDK_ROOT}/tools/linux/toolchain"
    if ./switch_gcc_version.sh 11 >/dev/null 2>&1; then
        # Verify the change
        if grep -q "BR2_TOOLCHAIN_EXTERNAL_GCC_11=y" \
           "${SDK_ROOT}/sysdrv/tools/board/buildroot/luckfox_pico_defconfig"; then
            log_test "Switch to GCC 11.2" "PASS"
        else
            log_test "Switch to GCC 11.2 (defconfig not updated)" "FAIL"
        fi
    else
        log_test "Switch to GCC 11.2 (command failed)" "FAIL"
    fi
    
    # Test 6: Switch back to GCC 8
    echo -e "${YELLOW}Test 6: Switch back to GCC 8.3.0${NC}"
    if ./switch_gcc_version.sh 8 >/dev/null 2>&1; then
        # Verify the change
        if grep -q "BR2_TOOLCHAIN_EXTERNAL_GCC_8=y" \
           "${SDK_ROOT}/sysdrv/tools/board/buildroot/luckfox_pico_defconfig"; then
            log_test "Switch back to GCC 8.3.0" "PASS"
        else
            log_test "Switch back to GCC 8.3.0 (defconfig not updated)" "FAIL"
        fi
    else
        log_test "Switch back to GCC 8.3.0 (command failed)" "FAIL"
    fi
    
    # Restore backup
    mv "/tmp/luckfox_pico_defconfig.backup" \
       "${SDK_ROOT}/sysdrv/tools/board/buildroot/luckfox_pico_defconfig"
else
    echo -e "${YELLOW}Tests 5-6: Skipped (GCC 11.2 not installed)${NC}"
    echo "  Install with: cd tools/linux/toolchain && ./install_gcc_11.2.sh"
fi

# Test 7: Check default GCC 8 toolchain
echo -e "${YELLOW}Test 7: Default GCC 8.3.0 toolchain${NC}"
if [ -x "${SDK_ROOT}/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/bin/arm-rockchip830-linux-uclibcgnueabihf-gcc" ]; then
    GCC8_VERSION=$(${SDK_ROOT}/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/bin/arm-rockchip830-linux-uclibcgnueabihf-gcc --version | head -n1)
    echo "  Installed: ${GCC8_VERSION}"
    log_test "GCC 8.3.0 toolchain present" "PASS"
else
    log_test "GCC 8.3.0 toolchain present" "FAIL"
fi

# Test 8: Check defconfig files
echo -e "${YELLOW}Test 8: Defconfig files${NC}"
if [ -f "${SDK_ROOT}/sysdrv/tools/board/buildroot/luckfox_pico_defconfig" ] && \
   [ -f "${SDK_ROOT}/sysdrv/tools/board/buildroot/luckfox_pico_w_defconfig" ]; then
    log_test "Defconfig files exist" "PASS"
else
    log_test "Defconfig files exist" "FAIL"
fi

# Test 9: Check documentation
echo -e "${YELLOW}Test 9: Documentation${NC}"
if [ -f "${SDK_ROOT}/tools/linux/toolchain/README.md" ] && \
   [ -f "${SDK_ROOT}/docs/GCC_VERSION_CONFIGURATION.md" ]; then
    log_test "Documentation files exist" "PASS"
else
    log_test "Documentation files exist" "FAIL"
fi

# Test 10: Check README updates
echo -e "${YELLOW}Test 10: README mentions GCC 11.2${NC}"
if grep -q "GCC 11.2" "${SDK_ROOT}/README.md"; then
    log_test "README.md mentions GCC 11.2" "PASS"
else
    log_test "README.md mentions GCC 11.2" "FAIL"
fi

# Summary
echo ""
echo -e "${BLUE}========================================"
echo "Test Results Summary"
echo -e "========================================${NC}"
echo ""

for result in "${TEST_RESULTS[@]}"; do
    if [[ $result == PASS:* ]]; then
        echo -e "${GREEN}$result${NC}"
    else
        echo -e "${RED}$result${NC}"
    fi
done

echo ""
echo -e "Total: ${GREEN}${TESTS_PASSED} passed${NC}, ${RED}${TESTS_FAILED} failed${NC}"
echo ""

if [ ${TESTS_FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
