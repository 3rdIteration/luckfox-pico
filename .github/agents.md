# Agent Instructions

## GPIO Changes

**Any time a GPIO-related change is required** (pinctrl, device tree pin configuration, pull resistor settings, input enable, IOMUX, or button/input configuration), **always consult the RV1106 GPIO User Manual** located at:

[`docs/Rockchip_RV1106_User_Manual_GPIO.pdf`](../docs/Rockchip_RV1106_User_Manual_GPIO.pdf)

This document contains the authoritative register maps, IOC domain layouts (PMU vs Base), pin multiplexing tables, pull-up/pull-down configuration details, and Input Enable (IE) register offsets for the RV1106 SoC. Failing to consult it risks introducing incorrect register offsets, missing IE configuration, or wrong pull resistor settings — all of which have caused real hardware failures (stuck buttons, pins latched LOW) in production.
