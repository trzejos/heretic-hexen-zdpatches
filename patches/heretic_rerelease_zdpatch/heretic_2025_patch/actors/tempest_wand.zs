class TempestWand : HereticWeapon {
    Default {
        Weapon.AmmoType "GoldWandAmmo";
        Weapon.AmmoUse 5;
        Weapon.SisterWeapon "TempestWandPowered";
        Weapon.SlotNumber 2;
        Inventory.PickupMessage "$TXT_WPNTEMPESTWAND";
        Tag "$TAG_WPNTEMPESTWAND";
        Obituary "$OB_MPTEMPESTWAND";

        +BLOODSPLATTER;
    }

    action void A_FireTempestWandPL1(double a, double b, double c, String pufftype, class<Actor> trailtype, double x, double y) {}
    action void A_ConsumeAmmo() {}

    States {
        Spawn:
            WSWN A -1;
            Stop;
        Select:
            SWND A 1 A_Raise;
            Wait;
        Deselect:
            SWND A 1 A_Lower;
            Wait;
        Ready:
            SWND A 1 A_WeaponReady;
            Wait;
        Fire:
            SWND B 4 Bright A_PlayWeaponSound("swnfir");
            SWND D 4 Bright A_FireTempestWandPL1(50, 8, 3, "TempestWandPuff", "TempestWandTrail", 16, 16);
            SWND C 4 Bright;
            SWND BAA 6;
            SWND A 0 A_ReFire;
            goto Ready;
        Hold:
            goto Fire;
    }
}

class TempestWandPowered : TempestWand {
    Default {
        Weapon.SisterWeapon "TempestWand";
        Weapon.AmmoUse 25;

        +WEAPON.POWERED_UP;
    }
    
    States {
        Fire:
            SWND A 10 Bright A_PlayWeaponSound("swnchg");
            SWND BCDE 5 Bright;
            SWND E 5 Bright A_ConsumeAmmo;
            SWND F 5 Bright A_FireProjectile("TempestWandBomb", 0, false);
            SWND C 5 Bright;
            SWND B 5 Bright A_ReFire;
            goto Ready;
        Hold:
            goto Fire;
    }
}

class TempestWandTrail : Actor {
    Default {
        Radius 8;
        Height 8;
        
        +NOBLOCKMAP;
        +NOGRAVITY;
    }

    States {
        Spawn:
            FX16 DEF 4 Bright;
            Stop;
    }
}

class TempestWandPuff : Actor {
    Default {
        Radius 20;
        Height 16;

        +NOBLOCKMAP;
        +NOGRAVITY;
        +PUFFONACTORS;
    }

    void A_TempestChain(double a, double b, double c, double d, String sound, class<Actor> trailtype, double x, double y) {}
}

class TempestWandPuff1 : TempestWandPuff {
    States {
        Spawn:
            FX18 OPQRS 4 Bright;
            Stop;
    }
}

class TempestWandPuff2 : TempestWandPuff {
    States {
        Spawn:
            FX16 GHI 4 Bright;
            FX16 J 4 Bright A_TempestChain(0, 512, 50, 80, "swnzap", "TempestWandTrail", 16, 16);
            FX16 KL 4 Bright;
            Stop;
    }
}

class TempestWandPuff3 : TempestWandPuff {
    States {
        Spawn:
            SWFX GHIJK 4 Bright;
            Stop;
    }
}

class TempestWandBomb : Actor {
    Default {
        Damage 1;
        Speed 15;
        Radius 12;
        Height 8;
        ReactionTime 3;
        Projectile;

        SeeSound "swnpow";
        DeathSound "swnhit";
        
        +RIPPER;
        +WINDTHRUST;
        +FULLVOLSEE;
        +FULLVOLDEATH;
        +FULLVOLACTIVE;
    }

    void A_TempestSpray(double a, double b, double c, double d, double e, class<Actor> pufftype, class<Actor> trailtype) {}
    void A_BlueSpark () {}
    void A_MissileCountdown() {}

    States {
        Spawn:
            FX16 ABC 3 Bright A_BlueSpark;
            FX16 C 0 Bright A_MissileCountdown;
            Loop;
        Death:
            SWFX A 5 Bright;
            SWFX B 5 Bright A_TempestSpray(360, 1024, 60, 80, 120, "TempestWandPuff3", "TempestWandTrail");
            SWFX CDEF 5 Bright;
            Stop;
    }
}
