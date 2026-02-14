# Luckfox Pico Toolchain Directory

This directory contains cross-compilation toolchains for the Luckfox Pico SDK.

## Available Toolchains

### GCC 8.3.0 (Default - Included)
- **Directory**: `arm-rockchip830-linux-uclibcgnueabihf/`
- **Status**: Pre-installed, fully tested
- **Use case**: Default for all users, best compatibility
- **Size**: ~233MB

### GCC 11.2 (Optional - Officially Supported)
- **Directory**: `gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/`
- **Status**: Officially supported per [Luckfox wiki](https://wiki.luckfox.com)
- **Use case**: Advanced users needing C++17/C++20, modern security features
- **Size**: ~400MB (after extraction)

## Quick Start

### Using GCC 8.3.0 (Default)

The default GCC 8.3.0 toolchain is already included. No additional setup needed.

```bash
cd arm-rockchip830-linux-uclibcgnueabihf/
source env_install_toolchain.sh
```

### Installing and Using GCC 11.2

**Step 1: Install GCC 11.2**
```bash
./install_gcc_11.2.sh
```

This script will:
- Download GCC 11.2 ARM toolchain from ARM Developer site (~100MB download)
- Extract and verify the installation (~400MB after extraction)
- Display next steps

**Step 2: Switch to GCC 11.2**
```bash
./switch_gcc_version.sh 11
```

This automatically updates the buildroot defconfig files to use GCC 11.2.

**Step 3: Build with GCC 11.2**
```bash
cd ../../../../
./build.sh clean
./build.sh lunch
./build.sh all
```

### Switching Back to GCC 8.3.0

```bash
./switch_gcc_version.sh 8
cd ../../../../
./build.sh clean
./build.sh lunch
./build.sh all
```

## Available Scripts

### `install_gcc_11.2.sh`
Downloads and installs the GCC 11.2 ARM toolchain.

**Features:**
- Automatic download from ARM Developer site
- Verification of installation
- Disk space check (requires ~500MB free)
- Cleanup of downloaded archive
- Detailed success/error messages

**Usage:**
```bash
./install_gcc_11.2.sh
```

### `switch_gcc_version.sh`
Switches between GCC 8.3.0 and GCC 11.2 by updating defconfig files.

**Features:**
- Automatically updates both defconfig files
- Validates toolchain availability
- No manual editing required

**Usage:**
```bash
./switch_gcc_version.sh 11    # Switch to GCC 11.2
./switch_gcc_version.sh 8     # Switch to GCC 8.3.0
```

## Manual Configuration

If you prefer to configure manually or use a different GCC version, edit the defconfig files:

- `sysdrv/tools/board/buildroot/luckfox_pico_defconfig`
- `sysdrv/tools/board/buildroot/luckfox_pico_w_defconfig`

See `docs/GCC_VERSION_CONFIGURATION.md` for complete instructions.

## GCC Version Comparison

| Feature | GCC 8.3.0 | GCC 11.2 |
|---------|-----------|----------|
| **Included** | ✅ Yes | ❌ No (requires download) |
| **C++ Standard** | C++14 | C++20 |
| **Size** | ~233MB | ~400MB |
| **Support** | Default/Tested | Official/Advanced |
| **Security** | Good | Better |
| **Compatibility** | Excellent | Good (may need fixes) |
| **Build Time** | Faster | ~10-20% slower |

## Troubleshooting

### GCC 11.2 download fails
- Check internet connection
- Verify you have wget or curl installed
- Try downloading manually from: https://developer.arm.com/downloads/-/gnu-a

### Not enough disk space
- Free up at least 500MB in the toolchain directory
- Or edit `install_gcc_11.2.sh` to keep the archive after installation

### Build errors after switching
- Always run `./build.sh clean` after switching GCC versions
- Some packages may need patches for newer GCC (see documentation)

### Want to use a different GCC version
- See `docs/GCC_VERSION_CONFIGURATION.md` for instructions on GCC 9, 10, 12, 13, or 14

## Additional Resources

- [GCC Version Configuration Guide](../../../docs/GCC_VERSION_CONFIGURATION.md)
- [Luckfox Wiki - Cross Compilation](https://wiki.luckfox.com/Luckfox-Pico-Plus-Mini/Cross-Compile/)
- [ARM GNU Toolchain Downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- [Buildroot External Toolchain Documentation](https://buildroot.org/downloads/manual/manual.html#_external_toolchain_backend)
