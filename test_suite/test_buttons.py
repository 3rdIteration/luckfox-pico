#!/usr/bin/env python3
"""
test_buttons.py — Interactive button press tester for LuckFox Pico Pi

Monitors all 8 SeedSigner button GPIOs and prints events in real time.
Press each button to confirm it works. Ctrl+C to exit.

Usage:
    python3 test_buttons.py
"""

import sys
import time

try:
    from periphery import GPIO
except ImportError:
    print('Error: python-periphery not installed')
    print('  pip install python-periphery')
    sys.exit(1)

BUTTONS = [
    # (name,       chip, line)
    ("KEY_RIGHT",  0,  0),
    ("KEY_DOWN",   0,  1),
    ("KEY_PRESS",  1, 20),
    ("KEY3",       1, 23),
    ("KEY_UP",     3, 25),
    ("KEY_LEFT",   3, 26),
    ("KEY2",       3, 27),
    ("KEY1",       4, 17),
]

POLL_HZ = 50
POLL_INTERVAL = 1.0 / POLL_HZ


def main():
    print()
    print('=' * 50)
    print('  SeedSigner Button Tester')
    print('  Press each button — Ctrl+C to exit')
    print('=' * 50)
    print()

    # Open all GPIO lines
    gpios = {}
    for name, chip, line in BUTTONS:
        try:
            g = GPIO(f'/dev/gpiochip{chip}', line, 'in')
            gpios[name] = g
        except Exception as e:
            print(f'  ✗ {name:12s}  gpiochip{chip} line {line}  open failed: {e}')

    if not gpios:
        print('No buttons could be opened.')
        sys.exit(1)

    # Read initial state
    prev = {}
    for name, g in gpios.items():
        try:
            prev[name] = g.read()
        except Exception:
            prev[name] = None

    # Show initial levels
    print('Initial state:')
    for name, chip, line in BUTTONS:
        if name in prev and prev[name] is not None:
            level = 'HIGH' if prev[name] else 'LOW'
            marker = '' if prev[name] else '  ← stuck low?'
            print(f'  {name:12s}  {level}{marker}')
        elif name in gpios:
            print(f'  {name:12s}  read error')
        # skip ones that failed to open

    pressed_set = set()
    total = len(gpios)

    print()
    print(f'Waiting for button presses ({total} buttons monitored)...')
    print()

    try:
        while True:
            for name, g in gpios.items():
                try:
                    val = g.read()
                except Exception:
                    continue

                if prev.get(name) is not None and val != prev[name]:
                    if not val:  # active low — pressed
                        pressed_set.add(name)
                        remaining = total - len(pressed_set)
                        print(f'  ▼ {name:12s}  PRESSED   '
                              f'[{len(pressed_set)}/{total} confirmed'
                              f'{", done!" if remaining == 0 else f", {remaining} remaining"}]')
                    else:
                        print(f'  ▲ {name:12s}  released')

                prev[name] = val

            if len(pressed_set) == total:
                print()
                print('All buttons confirmed working!')
                break

            time.sleep(POLL_INTERVAL)

    except KeyboardInterrupt:
        print()
        print()
        if pressed_set:
            print(f'Confirmed: {", ".join(sorted(pressed_set))}')
        not_pressed = set(gpios.keys()) - pressed_set
        if not_pressed:
            print(f'Not pressed: {", ".join(sorted(not_pressed))}')

    finally:
        for g in gpios.values():
            try:
                g.close()
            except Exception:
                pass


if __name__ == '__main__':
    main()
