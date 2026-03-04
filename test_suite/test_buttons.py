#!/usr/bin/env python3
"""
test_buttons.py — Interactive button press tester for LuckFox Pico boards

Auto-detects board variant (Pico Pi, Pico Pro Max, Pico Mini) via
/proc/device-tree/model and uses the correct GPIO pin mapping.

Usage:
    python3 test_buttons.py
    python3 test_buttons.py --board pi|max|mini
"""

import sys
import time
import argparse

try:
    from periphery import GPIO
except ImportError:
    print('Error: python-periphery not installed')
    print('  pip install python-periphery')
    sys.exit(1)

BOARD_BUTTONS = {
    "pi": [
        ("KEY_UP",     3, 25),
        ("KEY_DOWN",   0,  1),
        ("KEY_LEFT",   3, 26),
        ("KEY_RIGHT",  0,  0),
        ("KEY_PRESS",  1, 20),
        ("KEY1",       4, 17),
        ("KEY2",       3, 27),
        ("KEY3",       1, 23),
    ],
    "max": [
        ("KEY_UP",     1, 26),
        ("KEY_DOWN",   1, 21),
        ("KEY_LEFT",   1, 27),
        ("KEY_RIGHT",  1, 22),
        ("KEY_PRESS",  1, 20),
        ("KEY1",       1, 23),
        ("KEY2",       1, 11),
        ("KEY3",       1, 10),
    ],
    "mini": [
        ("KEY_UP",     1, 25),
        ("KEY_DOWN",   1, 27),
        ("KEY_LEFT",   1, 24),
        ("KEY_RIGHT",  1, 22),
        ("KEY_PRESS",  1, 26),
        ("KEY1",       1, 23),
        ("KEY2",       0,  4),
        ("KEY3",       1, 21),
    ],
}

POLL_HZ = 50
POLL_INTERVAL = 1.0 / POLL_HZ

def detect_board():
    try:
        with open('/proc/device-tree/model', 'r') as f:
            model = f.read().strip().rstrip('\x00').lower()
    except (FileNotFoundError, PermissionError):
        return None
    if 'pico pro max' in model or 'pico max' in model:
        return 'max'
    elif 'pico mini' in model or 'pico plus' in model:
        return 'mini'
    elif 'pico pi' in model:
        return 'pi'
    return None

def main():
    parser = argparse.ArgumentParser(description='SeedSigner Button Tester')
    parser.add_argument('--board', choices=['pi', 'max', 'mini'],
                        help='Force board type (auto-detected if omitted)')
    args = parser.parse_args()

    board = args.board or detect_board()
    if board is None:
        print('Could not auto-detect board variant.')
        print('Use --board pi|max|mini to specify manually.')
        sys.exit(1)

    buttons = BOARD_BUTTONS[board]
    board_names = {'pi': 'Pico Pi', 'max': 'Pico Pro Max', 'mini': 'Pico Mini'}

    print()
    print('=' * 50)
    print(f'  SeedSigner Button Tester -- {board_names[board]}')
    print('  Press each button -- Ctrl+C to exit')
    print('=' * 50)
    print()

    gpios = {}
    for name, chip, line in buttons:
        try:
            g = GPIO(f'/dev/gpiochip{chip}', line, 'in')
            gpios[name] = g
        except Exception as e:
            print(f'  x {name:12s}  gpiochip{chip} line {line}  open failed: {e}')

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
    for name, chip, line in buttons:
        if name in prev and prev[name] is not None:
            level = 'HIGH' if prev[name] else 'LOW'
            marker = '' if prev[name] else '  <- stuck low?'
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
                        print(f'  v {name:12s}  PRESSED   '
                              f'[{len(pressed_set)}/{total} confirmed'
                              f'{", done!" if remaining == 0 else f", {remaining} remaining"}]')
                    else:
                        print(f'  ^ {name:12s}  released')

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
