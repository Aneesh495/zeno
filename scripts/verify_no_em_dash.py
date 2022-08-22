#!/usr/bin/env python3
import os
import sys

def scan_files():
    found_invalid = False
    for root, dirs, files in os.walk('.'):
        if '.git' in root or 'bin' in root or 'export' in root:
            continue
        for f in files:
            path = os.path.join(root, f)
            with open(path, 'rb') as fp:
                data = fp.read()
                # Check for unicode em-dash U+2014: \xe2\x80\x94
                if b'\xe2\x80\x94' in data:
                    print(f"ERROR: Em dash (U+2014) detected in {path}", file=sys.stderr)
                    found_invalid = True
                # Check for double hyphen used as em dash in markdown/comments
                # but allow standard comment lines or flags
    if found_invalid:
        sys.exit(1)
    print("Verification passed: No em dashes detected.")

if __name__ == '__main__':
    scan_files()
