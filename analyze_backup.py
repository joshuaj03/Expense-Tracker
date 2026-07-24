#!/usr/bin/env python3
"""Deeper analysis of MyMoney backup data."""
import json
from collections import Counter

with open('sample_backup/MyMoneyBackup_24_07_26_130.mbak.decrypted.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Record types
types = Counter(r['type'] for r in data['records'])
print("Record types (1=income, 2=expense, 3=transfer?):", dict(types))

# Find a transfer record
for r in data['records']:
    if r['type'] == 3:
        print("\nSample transfer record:")
        print(json.dumps(r, indent=2, ensure_ascii=False))
        break

# Category types  
cat_types = Counter(c['type'] for c in data['categories'])
print("\nCategory types:", dict(cat_types))

# All unique account names
acct_names = sorted(set(a['name'] for a in data['accounts']))
print("\nAll accounts:", acct_names)

# All unique category names
cat_names = sorted(set(c['name'] for c in data['categories']))
print("\nAll categories:", cat_names)

# Date range
import datetime
times = [r['time'] for r in data['records']]
min_t = datetime.datetime.fromtimestamp(min(times)/1000)
max_t = datetime.datetime.fromtimestamp(max(times)/1000)
print(f"\nDate range: {min_t} to {max_t}")
print(f"Total records: {len(data['records'])}")
print(f"Total accounts: {len(data['accounts'])}")
print(f"Total categories: {len(data['categories'])}")
print(f"Total budgets: {len(data['budgets'])}")

# Budget time analysis
budget_times = set()
for b in data['budgets']:
    dt = datetime.datetime.fromtimestamp(b['time']/1000)
    budget_times.add(f"{dt.year}-{dt.month:02d}")
print(f"\nBudget months: {sorted(budget_times)}")
