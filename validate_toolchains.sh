#!/bin/bash
# Validation script for dual toolchain configuration

echo "==================================================================="
echo "Dual Toolchain Configuration Validation"
echo "==================================================================="
echo ""

# Change to sysdrv directory
cd "$(dirname "$0")/sysdrv" || exit 1

# Run make info to show configuration
echo "Running 'make info' to display configuration..."
echo ""
make info BOOT_MEDIUM=emmc 2>&1 | grep -A 20 "TOOLCHAIN INFO\|C LIBRARY TYPE"

echo ""
echo "==================================================================="
echo "Checking if toolchains are available..."
echo "==================================================================="
echo ""

# Extract toolchain names from cfg.mk
BOOT_TC=$(grep "^CONFIG_SYSDRV_CROSS_BOOT" cfg/cfg.mk | awk -F':= ' '{print $2}')
USERSPACE_TC=$(grep "^CONFIG_SYSDRV_CROSS_USERSPACE" cfg/cfg.mk | awk -F':= ' '{print $2}')

echo "Boot toolchain:      ${BOOT_TC}"
echo "Userspace toolchain: ${USERSPACE_TC}"
echo ""

# Check if boot toolchain exists
if which "${BOOT_TC}-gcc" >/dev/null 2>&1; then
    echo "✓ Boot toolchain found: $(which ${BOOT_TC}-gcc)"
    echo "  Version: $(${BOOT_TC}-gcc --version | head -1)"
else
    echo "✗ Boot toolchain NOT FOUND: ${BOOT_TC}-gcc"
    echo "  Please install this toolchain before building."
fi
echo ""

# Check if userspace toolchain exists
if which "${USERSPACE_TC}-gcc" >/dev/null 2>&1; then
    echo "✓ Userspace toolchain found: $(which ${USERSPACE_TC}-gcc)"
    echo "  Version: $(${USERSPACE_TC}-gcc --version | head -1)"
else
    echo "✗ Userspace toolchain NOT FOUND: ${USERSPACE_TC}-gcc"
    echo "  Please install this toolchain before building."
fi
echo ""

echo "==================================================================="
echo "Validation Summary"
echo "==================================================================="
echo ""
echo "Configuration:"
echo "  - Boot/Kernel uses: ${BOOT_TC}"
echo "  - Userspace uses:   ${USERSPACE_TC}"
echo ""
echo "This configuration allows:"
echo "  ✓ Lightweight uClibc for boot and kernel"
echo "  ✓ Full glibc for userspace applications"
echo ""
echo "For more information, see DUAL_TOOLCHAIN.md"
echo ""
