# Heretic + Hexen (2025) Patches for GZDoom

## What This Is

This is a collection of patches for GZDoom that allow users to play with the new features of
Heretic + Hexen by Nightdive Studios, including the new Faith Renewed and Vestiges of Grandeur
episodes. Changes made by the "enhanced" enemy/weapon/item behavior toggles is not implemented

This is mostly complete, but not 100% accurate. This was implemented based on inspection of the
EXDEFS definitions and trying to replicate behavior observed in the Nightdive port.

Notable differences include:
- Heretic
  - Monster attack functions are mostly guessed on, damage should be close. Notably, the chaos
    serpent enemies can use vertical aiming, so they are more of a threat.
  - Tempest wand is implemented, but the damage may be off. Still it should serve as a suitable
    BFG type weapon.
- Hexen
  - Class changing is not supported. There is a ZScript level postprocessor and ACS library that can
    be loaded to print messages when these specials are used/activated. They can be removed and the
    specials will just do nothing instead.

The "patches" directory contains folders that can be used by gzdoom directly:
- The "common" patch contains all the actor definitions. It can be safely autoloaded to enable the
  new features to work when the Nightdive IWADs are used
- The "heretic" patch contains PNG versions of the fullscreen raw graphics in heretic.wad
- The "fr" patch contains PNG versions of the fullscreen raw graphics in heretic_fr.wad
- The "hexen" patch contains PNG versions of the fullscreen raw graphics in hexen.wad
- The "hexdd" patch contains PNG versions of the fullscreen raw graphics in hexdd.wad
- The "vog" patch contains PNG versions of the fullscreen raw graphics in hexen_vog.wad
