#!/usr/bin/env python3
"""Small nextpnr --run helper for interactive chipdb API discovery."""

names = [
    name
    for name in dir(ctx)
    if "Wire" in name
    or "wire" in name
    or "Pip" in name
    or "pip" in name
    or "Bel" in name
    or "bel" in name
    or "Name" in name
    or "name" in name
]
for name in sorted(names):
    print(name)
