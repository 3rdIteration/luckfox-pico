# OV5640 / OV5645 Camera Adapter Wiring Guide for Luckfox Pico

The Luckfox Pico (RV1103/RV1106) boards natively support SmartSens camera
modules (SC3336, SC4336, etc.) via a MIPI CSI-2 FPC connector.  OmniVision
OV5640 and OV5645 modules — commonly sold as "Raspberry Pi–style" camera
boards — use the **same** MIPI CSI-2 interface but at a **different I2C
address** (0x3C instead of 0x30) and may have a different FPC pinout.

This document explains which signals must be connected and how to build a
simple adapter board or re-pin cable.

---

## 1. Signals Required

All data comes from the device-tree configuration in
`rv1103-luckfox-pico-ipc.dtsi` and the kernel pinctrl definitions.

| Signal | RV1103/RV1106 Pin | Function | Notes |
|---|---|---|---|
| MIPI_CLK0_P | GPIO3_C1 | CSI-2 clock lane + | Directly to sensor CLK_P |
| MIPI_CLK0_N | GPIO3_C0 | CSI-2 clock lane − | Directly to sensor CLK_N |
| MIPI_D0_P | GPIO3_C3 | CSI-2 data lane 0 + | Directly to sensor D0_P |
| MIPI_D0_N | GPIO3_C2 | CSI-2 data lane 0 − | Directly to sensor D0_N |
| MIPI_D1_P | GPIO3_B7 | CSI-2 data lane 1 + | Directly to sensor D1_P |
| MIPI_D1_N | GPIO3_B6 | CSI-2 data lane 1 − | Directly to sensor D1_N |
| I2C4_SCL | GPIO3_C7 | I2C clock (400 kHz) | 2.2 kΩ pull-up to 1.8 V |
| I2C4_SDA | GPIO3_D0 | I2C data | 2.2 kΩ pull-up to 1.8 V |
| MCLK | GPIO3_C4 | 24 MHz reference clock | `mipi_refclk_out0` output |
| PWDN / EN | GPIO3_C5 | Power-down (OV5640) or Enable (OV5645) | Active-HIGH |
| VCC_1V8 | — | 1.8 V digital I/O supply | Board regulator |
| VCC_3V3 | — | 3.3 V / 2.8 V analog supply | See §3 below |
| GND | — | Ground | Connect all GND pins |

> **Tip:** The Luckfox Pico already provides VCC_1V8 and VCC_3V3 as always-on
> regulators.  If your OV5640 module has an on-board LDO that converts 3.3 V to
> 2.8 V AVDD and 1.5 V DVDD, you only need to supply 3.3 V and 1.8 V.

---

## 2. Typical OV5640 MIPI Module Pinout (24-pin FPC)

Most generic OV5640 MIPI CSI-2 modules use a 24-pin 0.5 mm pitch FPC with
this pinout (verify against your specific module's datasheet):

| Module Pin | Signal | Connect To |
|---|---|---|
| 1 | GND | GND |
| 2 | MIPI_D0_N | GPIO3_C2 (MIPI_D0_N) |
| 3 | MIPI_D0_P | GPIO3_C3 (MIPI_D0_P) |
| 4 | GND | GND |
| 5 | MIPI_D1_N | GPIO3_B6 (MIPI_D1_N) |
| 6 | MIPI_D1_P | GPIO3_B7 (MIPI_D1_P) |
| 7 | GND | GND |
| 8 | MIPI_CLK_N | GPIO3_C0 (MIPI_CLK0_N) |
| 9 | MIPI_CLK_P | GPIO3_C1 (MIPI_CLK0_P) |
| 10 | GND | GND |
| 11 | NC | — |
| 12 | NC | — |
| 13 | I2C_SCL | GPIO3_C7 (I2C4_SCL) |
| 14 | I2C_SDA | GPIO3_D0 (I2C4_SDA) |
| 15 | NC | — |
| 16 | NC | — |
| 17 | XCLK (MCLK) | GPIO3_C4 (MCLK_REF_MIPI0) |
| 18 | NC | — |
| 19 | NC | — |
| 20 | PWDN | GPIO3_C5 (active HIGH) |
| 21 | NC / RESET | Optional — see §4 |
| 22 | VCC_1V8 (DOVDD) | 1.8 V |
| 23 | VCC_2V8 (AVDD) | 2.8 V (or 3.3 V if module has LDO) |
| 24 | VCC_1V5 (DVDD) | 1.5 V (or supplied by module LDO) |

> **Important:** Pin numbering varies between manufacturers. Always check your
> module's datasheet before wiring.

---

## 3. Power Supply Notes

The OV5640 requires three supply rails:

| Rail | Voltage | Typical Current | Source on Luckfox Pico |
|---|---|---|---|
| DOVDD (digital I/O) | 1.8 V | ~20 mA | VCC_1V8 regulator |
| AVDD (analog) | 2.8 V | ~80 mA | Use external LDO from VCC_3V3 |
| DVDD (digital core) | 1.5 V | ~120 mA | Use external LDO from VCC_3V3 |

Many OV5640 breakout boards include on-board LDOs that derive AVDD (2.8 V) and
DVDD (1.5 V) from a single 3.3 V input.  If your module has these LDOs, simply
supply **3.3 V** and **1.8 V** from the Luckfox Pico.

If your module exposes the raw sensor pins, you will need small LDOs
(e.g. AP2112 3.3→2.8 V, AP2112 3.3→1.5 V) on the adapter board.

---

## 4. Reset GPIO (Optional)

The current device-tree configuration does **not** assign a dedicated reset
GPIO for the OV5640.  The OV5640 driver treats the reset pin as optional — the
sensor will be powered up using only the power-down pin.

If your module has a RESET pin and you want to use it, you can connect it to a
spare GPIO and update the device tree:

```dts
ov5640: ov5640@3c {
    /* ... existing properties ... */
    reset-gpios = <&gpio_bank GPIO_PIN GPIO_ACTIVE_LOW>;
};
```

---

## 5. Adapter Board Schematic (Minimal)

```
Luckfox Pico CSI Connector              OV5640 Module (24-pin FPC)
┌──────────────────────┐                ┌──────────────────────┐
│                      │                │                      │
│  MIPI_CLK0_P  ───────┼────────────────┼──  MIPI_CLK_P        │
│  MIPI_CLK0_N  ───────┼────────────────┼──  MIPI_CLK_N        │
│  MIPI_D0_P    ───────┼────────────────┼──  MIPI_D0_P         │
│  MIPI_D0_N    ───────┼────────────────┼──  MIPI_D0_N         │
│  MIPI_D1_P    ───────┼────────────────┼──  MIPI_D1_P         │
│  MIPI_D1_N    ───────┼────────────────┼──  MIPI_D1_N         │
│                      │                │                      │
│  I2C4_SCL     ───────┼──┬─────────────┼──  I2C_SCL           │
│                      │  ├─ 2.2kΩ ─ 1.8V                      │
│  I2C4_SDA     ───────┼──┬─────────────┼──  I2C_SDA           │
│                      │  ├─ 2.2kΩ ─ 1.8V                      │
│                      │                │                      │
│  MCLK (GPIO3_C4) ───┼────────────────┼──  XCLK              │
│  PWDN (GPIO3_C5) ───┼────────────────┼──  PWDN              │
│                      │                │                      │
│  VCC_1V8      ───────┼────────────────┼──  DOVDD (1.8V)      │
│  VCC_3V3      ───────┼──[LDO 2.8V]───┼──  AVDD  (2.8V)      │
│  VCC_3V3      ───────┼──[LDO 1.5V]───┼──  DVDD  (1.5V)      │
│  GND          ───────┼────────────────┼──  GND               │
│                      │                │                      │
└──────────────────────┘                └──────────────────────┘
```

If your OV5640 module already has on-board voltage regulators, replace the LDO
blocks above with direct 3.3 V connections to the module's VIN/VCC_3V3 pin.

---

## 6. OV5645 Differences

The OV5645 is pin-compatible with many OV5640 modules but the driver uses
slightly different GPIO naming:

| Property | OV5640 | OV5645 |
|---|---|---|
| Power-down GPIO | `powerdown-gpios` (active HIGH) | `enable-gpios` (active HIGH) |
| Reset GPIO | `reset-gpios` (active LOW, optional) | Not used in this config |
| Power supply names (DT) | `DOVDD`, `AVDD`, `DVDD` | `vdddo`, `vdda`, `vddd` |

The physical wiring is identical — use the same adapter for either sensor.

---

## 7. Verifying the Connection

After wiring and flashing firmware with OV5640/OV5645 support:

```sh
# Check if the sensor is detected on I2C
i2cdetect -y 4
# Address 0x3c should show up if the sensor is powered and connected

# Check kernel logs for camera driver probe
dmesg | grep -i "ov5640\|ov5645\|camera"

# List video devices
ls /dev/video*

# Capture a test frame (if v4l2-ctl is available)
v4l2-ctl --device /dev/video0 --stream-mmap --stream-count=1 --stream-to=test.raw
```

---

## 8. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `i2cdetect` shows nothing at 0x3c | Sensor not powered or I2C not connected | Check DOVDD (1.8 V), PWDN pin, I2C wiring |
| Driver probe fails in `dmesg` | Clock not reaching sensor | Verify MCLK (24 MHz) on GPIO3_C4 |
| No `/dev/video*` device | Driver not loaded | Run `modprobe ov5640` or check `CONFIG_VIDEO_OV5640=m` |
| Image is black | MIPI lanes swapped or disconnected | Verify differential pair connections |
| Image has artifacts | Signal integrity issue | Keep MIPI traces short (<5 cm), use impedance-matched pairs |
