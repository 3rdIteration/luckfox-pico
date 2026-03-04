# Agent Instructions

## GPIO Changes

**Any time a GPIO-related change is required** (pinctrl, device tree pin configuration, pull resistor settings, input enable, IOMUX, or button/input configuration), **always consult the RV1106 GPIO User Manual** located at:

[`docs/Rockchip_RV1106_User_Manual_GPIO.pdf`](../docs/Rockchip_RV1106_User_Manual_GPIO.pdf)

This document contains the authoritative register maps, IOC domain layouts (PMU vs Base), pin multiplexing tables, pull-up/pull-down configuration details, and Input Enable (IE) register offsets for the RV1106 SoC. Failing to consult it risks introducing incorrect register offsets, missing IE configuration, or wrong pull resistor settings — all of which have caused real hardware failures (stuck buttons, pins latched LOW) in production.

Also review the hardware testing report for real-world validation data:

[`docs/RV1106_GPIO_Button_Testing_Report.md`](../docs/RV1106_GPIO_Button_Testing_Report.md)

This report documents hands-on testing of all 8 SeedSigner button pins on the LuckFox Pico Pi, including verified IOC register values for each GPIO bank, the `io` tool diagnostic commands, and the critical finding that `bias-pull-up` (not `bias-disable`) is required for GPIO3 D-group pins due to the NDC7002N MOSFET level shifter circuit.

## GPIO Test Suite

On-device button validation scripts are located in [`test_suite/`](../test_suite/):

- **`test_buttons.py`** — Interactive button press tester. Monitors all 8 SeedSigner button GPIOs via python-periphery, detects press/release events, and confirms each button works. Run on-device after flashing to validate GPIO configuration.
