# Dual Toolchain Support

This repository has been modified to support using separate toolchains for boot/kernel components and userspace applications.

## Overview

The build system now supports:
- **Boot Toolchain (uClibc)**: Used for compiling U-Boot and Linux kernel
- **Userspace Toolchain (glibc)**: Used for compiling userspace applications (busybox/buildroot)

This allows you to use a lightweight uClibc toolchain for boot and kernel components while using glibc for userspace applications that may require better compatibility.

## Default Configuration

By default, the build system is configured to use:
- **Boot/Kernel**: `arm-rockchip830-linux-uclibcgnueabihf` (uClibc)
- **Userspace**: `arm-rockchip830-linux-gnueabihf` (glibc)

This is configured in `sysdrv/cfg/cfg.mk`.

## How It Works

### Configuration Variables

The following variables control toolchain selection:

#### In cfg.mk or Makefile:
- `CONFIG_SYSDRV_CROSS_BOOT`: Toolchain prefix for U-Boot and kernel
- `CONFIG_SYSDRV_CROSS_USERSPACE`: Toolchain prefix for userspace
- `CONFIG_SYSDRV_CROSS`: Legacy single toolchain (for backward compatibility)

#### From Environment or Command Line:
- `RK_TOOLCHAIN_CROSS_BOOT`: Override boot toolchain
- `RK_TOOLCHAIN_CROSS_USERSPACE`: Override userspace toolchain
- `RK_TOOLCHAIN_CROSS`: Legacy override (sets both if individual ones not set)

### Build Targets

Different components use different toolchains:

| Component | Toolchain Used | Make Target |
|-----------|----------------|-------------|
| U-Boot | Boot (uClibc) | `make uboot` |
| Linux Kernel | Boot (uClibc) | `make kernel` |
| Kernel Modules | Boot (uClibc) | `make drv` |
| Busybox | Userspace (glibc) | `make busybox` |
| Buildroot | Userspace (glibc) | `make buildroot` |

### Runtime Libraries

The runtime libraries (shared libraries) installed to the rootfs are taken from the **userspace toolchain**, since userspace applications need to link against these libraries.

## Usage Examples

### Using Default Dual Toolchain Configuration

Simply build as usual:

```bash
cd sysdrv
make all
```

This will use uClibc for boot/kernel and glibc for userspace.

### Customizing Toolchains

You can customize toolchains in several ways:

#### 1. Edit Configuration File

Edit `sysdrv/cfg/cfg.mk`:

```makefile
CONFIG_SYSDRV_CROSS_BOOT := arm-rockchip830-linux-uclibcgnueabihf
CONFIG_SYSDRV_CROSS_USERSPACE := arm-rockchip830-linux-gnueabihf
```

#### 2. Environment Variables

Set environment variables before building:

```bash
export RK_TOOLCHAIN_CROSS_BOOT=arm-rockchip830-linux-uclibcgnueabihf
export RK_TOOLCHAIN_CROSS_USERSPACE=arm-rockchip830-linux-gnueabihf
cd sysdrv
make all
```

#### 3. Command Line Override

Pass toolchains directly to make:

```bash
cd sysdrv
make SYSDRV_CROSS_BOOT=arm-rockchip830-linux-uclibcgnueabihf \
     SYSDRV_CROSS_USERSPACE=arm-rockchip830-linux-gnueabihf \
     all
```

### Using Single Toolchain (Backward Compatibility)

To use the same toolchain for everything (legacy behavior):

```bash
cd sysdrv
make SYSDRV_CROSS=arm-rockchip830-linux-uclibcgnueabihf all
```

Or set only `CONFIG_SYSDRV_CROSS` in `cfg.mk`.

## Board Configuration Files

Board configuration files in `project/cfg/BoardConfig_IPC/` can also specify toolchains:

```bash
# For dual toolchain:
export RK_TOOLCHAIN_CROSS_BOOT=arm-rockchip830-linux-uclibcgnueabihf
export RK_TOOLCHAIN_CROSS_USERSPACE=arm-rockchip830-linux-gnueabihf

# Or for single toolchain (legacy):
export RK_TOOLCHAIN_CROSS=arm-rockchip830-linux-uclibcgnueabihf
```

## Toolchain Requirements

### Boot Toolchain (uClibc)
- Must support the target architecture (ARM/ARM64)
- Should be lightweight and suitable for embedded boot/kernel compilation
- Example: `arm-rockchip830-linux-uclibcgnueabihf`

### Userspace Toolchain (glibc)
- Must support the same architecture as boot toolchain
- Should provide glibc for better application compatibility
- Example: `arm-rockchip830-linux-gnueabihf`

**Important**: Both toolchains must be installed and available in your PATH before building.

## Verification

To verify which toolchains will be used:

```bash
cd sysdrv
make info
```

This will display the configured toolchains and other build settings.

## Troubleshooting

### Toolchain Not Found

If you see an error like:
```
Not found tool xxx-gcc, please install first !!!
```

Make sure:
1. The toolchain is installed
2. The toolchain binaries are in your PATH
3. The toolchain name is spelled correctly

### Mixed C Library Errors

If you encounter linking errors about mixed uClibc/glibc symbols:
- Verify that boot components (kernel modules) are not being linked with userspace libraries
- Check that the correct toolchain is being used for each component

### Runtime Library Errors

If applications fail to run with library errors:
- The runtime libraries from the userspace toolchain should be in the rootfs
- Check that `TOOLCHAIN_RUNTIME_LIB` is being installed correctly

## Implementation Details

The dual toolchain support is implemented in:
- `sysdrv/Makefile.param`: Toolchain detection and variable setup
- `sysdrv/Makefile`: Build targets updated to use appropriate toolchains
- `sysdrv/cfg/cfg.mk`: Default toolchain configuration

Key exported variables:
- `CROSS_COMPILE_BOOT`: Boot toolchain prefix with trailing dash
- `CROSS_COMPILE_USERSPACE`: Userspace toolchain prefix with trailing dash
- `CROSS_COMPILE`: Legacy variable (defaults to userspace for compatibility)
