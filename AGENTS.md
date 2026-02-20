# Repository notes for agents

- This repository uses a customized Buildroot stack for Luckfox Pico devices and is not a standard upstream Buildroot layout/workflow.
- Builds are expected to use the custom Rockchip830 uClibc toolchain bundled with this repository.
- Changes do **not** need to maintain glibc or musl compatibility unless explicitly requested.
