#!/usr/bin/env python3
"""Inspect the decrypted MyMoney JSON to understand its structure."""
import json

with open('sample_backup/MyMoneyBackup_24_07_26_130.mbak.decrypted.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("Top-level keys:", list(data.keys()))
for key in data:
    items = data[key]
    if isinstance(items, list):
        print(f"\n--- {key}: {len(items)} items ---")
        if len(items) > 0:
            print("Sample (first item):")
            print(json.dumps(items[0], indent=2, ensure_ascii=False))
            if len(items) > 1:
                print("\nSample (second item):")
                print(json.dumps(items[1], indent=2, ensure_ascii=False))
    else:
        print(f"\n--- {key}: {type(items).__name__} ---")
        print(str(items)[:200])
