# Heretic + Hexen (2025) Patches for UZDoom

## What This Is

This is a collection of patches for UZDoom that allow users to play with the new features of
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

## Usage

Precompiled PK3s are available on the [releases page](https://github.com/trzejos/heretic-hexen-zdpatches/releases/latest).

The following sections contain the load order of files UZDoom needs to play different games. Files that are **bolded** are IWADs, and files that are _italicized_ are optional. Other gameplay mods may be loaded afterwards if desired.

> [!IMPORTANT]  
> IWADs used with this _must_ be from the KEX rerelease since they contain the assets required for all new actors.

> [!TIP]
> The `hh_patch_common.pk3` file used in all cases should be safe to autoload, but is untested in multiplayer games
> with others not using it.

#### Heretic: KEX Edition

- **`heretic.wad`**
- `hh_patch_common.pk3`
- _`heretic_ex.wad`_ - Only needed for "enhanced" maps
- `hh_patch_heretic.pk3` - Only contains title graphics

#### Heretic: Faith Renewed

- **`heretic.wad`**
- `hh_patch_common.pk3`
- `heretic_fr.wad`
- `hh_patch_fr.pk3` - Only contains title graphics

#### Hexen: KEX Edition

- **`hexen.wad`**
- `hh_patch_common.pk3`
- _`hexen_ex.wad`_ - Adds scripted map markers and the non-functional class changing tome
- `hh_patch_hexen.pk3` - Only contains title graphics

#### Hexen: Deathkings KEX Edition

- **`hexen.wad`**
- `hh_patch_common.pk3`
- _`hexdd_ex.wad`_ - Adds scripted map markers and the non-functional class changing tome
- `hh_patch_hexdd.pk3` - Only contains title graphics

#### Hexen: Vestiges of Grandeur

- **`hexen.wad`**
- `hh_patch_common.pk3`
- `hexen_vog.wad`
- `hh_patch_vog.pk3` - Only contains title graphics
