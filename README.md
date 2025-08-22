# Heretic + Hexen (2025) Patches for GZDoom

## What This Is

This is a collection of patches for GZDoom that allow users to play with the new features of
Heretic + Hexen by Nightdive Studios, including the new Faith Renewed and Vestiges of Grandeur
episodes.

Note this is very WIP. The hexen patches should mostly work, but the new monsters and weapons in
Heretic have some code pointers that don't directly translate to GZDoom, so some extra work is needed there.

The raw graphics in the rerelease wads are 560x200. The convert.py script can convert them, but I haven't
tested this on a wide range of systems.

The Draugr, Chaos Serpent, and Troll behavior is based off of inspection of the EXDEFS configuration in heretic.wad, MBF21 action function documentation, and observing behavior in the official port. Some things may be slightly off, but should be close.
