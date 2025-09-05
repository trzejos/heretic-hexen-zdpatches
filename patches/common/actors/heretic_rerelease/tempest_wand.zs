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

    // A_FireTempestWandPL1(50, 8, 3, "TempestWandPuff", "TempestWandTrail", 16, 16);
    action void A_FireTempestWandPL1(int basedmg, int randomdmg, int maxhops, class<Actor> pufftype, class<Actor> trailtype, double trailspread, double traildist) {
        MBF21_ConsumeAmmo(0);
        FRailParams p;
        p.damage = 0; p.distance = PLAYERMISSILERANGE; p.offset_xy = 0; p.offset_z = 0; p.puff = null;
        p.flags = RGF_NOPIERCING; p.spawnclass = trailtype; p.maxdiff = trailspread * 2; p.sparsity = traildist;
        RailAttack(p);
        int dmg = basedmg + 3 * Random(1, randomDmg);
        FTranslatedLineTarget victim;
        let puff = LineAttack(Angle, PLAYERMISSILERANGE, BulletSlope(), dmg, 'Hitscan', pufftype, LAF_NORANDOMPUFFZ, victim);
        puff.ReactionTime = maxhops;
        puff.tracer = victim.linetarget;
    }

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
            SWND E 5 Bright MBF21_ConsumeAmmo(0);
            SWND F 5 Bright MBF21_WeaponProjectile("TempestWandBomb", 0, 0, 0, 0);
            SWND C 5 Bright;
            SWND B 5 Bright A_ReFire;
            goto Ready;
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
        ReactionTime 0;

        SeeSound "swnhit";
        AttackSound "swnmis";

        +NOBLOCKMAP;
        +NOGRAVITY;
        +ALWAYSPUFF;
        +PUFFONACTORS;
        +PUFFGETSOWNER;
    }

    // Return true if mo is the shooter or one of the chain targets
    bool CheckTargets(Actor mo) {
        // Start at this puff
        Actor puff = self;
        while(puff) {
            if (mo == puff.tracer)
                return true;
            // Check previous puff
            puff = puff.target;
            if (!TempestWandPuff(puff))
                // If the target isn't a puff, it must be the player who initiated the attack
                return mo == puff;
        }
        return false;
    }

    // A_TempestChain(0, 512, 50, 80, "swnzap", "TempestWandTrail", 16, 16);
    void A_TempestChain(double mindist, double maxdist, int mindmg, int maxdmg, String sound, class<Actor> trailtype, double trailspread, double traildist) {
        // End of the chain
        if (ReactionTime <= 0)
            return;

        // Find nearest actor within maxdist
        Actor next = null;
        double distance = maxdist;
        let bti = BlockThingsIterator.Create(self, maxdist);
        while (bti.Next()) {
            let mo = bti.thing;
            if (!mo || CheckTargets(mo)) // Skip shooter and previous targets
                continue;
            if (!mo.bSolid || !mo.bShootable) // Skip non-solid/non-shootable actors
                continue;
            if (Distance2D(mo) > distance || Distance2D(mo) < mindist) // Distance check
                continue;
            if (!CheckSight(mo, SF_IGNOREWATERBOUNDARY|SF_IGNOREVISIBILITY)) // Line of sight check
                continue;
            // Record nearest distance and next target in chain
            distance = Distance2D(mo);
            next = mo;
        }

        // End chain early if no next target could be found
        if (!next)
            return;

        // Play the sound
        A_StartSound(sound);

        let a = AngleTo(next);
        self.Angle = a;

        // Spawn trail actors
        A_CustomRailgun(0, 0, "", "", RGF_SILENT, 0, trailspread * 2, "", 0, 0, distance, 0, traildist, 0, trailtype);

        // Spawn next puff
        FTranslatedLineTarget victim;
        let p = AimLineAttack(a, PLAYERMISSILERANGE);
        let puff = LineAttack(a, PLAYERMISSILERANGE, p, Random(mindmg, maxdmg), 'Hitscan', "TempestWandPuff", LAF_NORANDOMPUFFZ, victim);
        puff.ReactionTime = self.ReactionTime - 1;
        puff.target = self;
        puff.tracer = victim.linetarget;
    }

    States {
        Spawn:
        XDeath:
            FX16 GHI 4 Bright;
            FX16 J 4 Bright A_TempestChain(0, 512, 50, 80, "swnzap", "TempestWandTrail", 16, 16);
            FX16 KL 4 Bright;
            Stop;
        Crash:
            FX18 OPQRS 4 Bright;
            Stop;
    }
}

class TempestSprayPuff : TempestWandPuff {
    States {
        Spawn:
        XDeath:
            SWFX GHIJK 4 Bright;
            Stop;
    }
}

class TempestWandBomb : Sorcerer2FX1 {
    Default {
        Speed 15;
        FastSpeed 15;
        Radius 12;
        Height 8;
        ReactionTime 3;
        RenderStyle "Normal";
        Projectile;

        SeeSound "swnpow";
        DeathSound "swnhit";
        
        +RIPPER;
        +WINDTHRUST;
        +FULLVOLSEE;
        +FULLVOLDEATH;
        +FULLVOLACTIVE;
        +ACTIVATEIMPACT;
        +ACTIVATEPCROSS;
        -ZDOOMTRANS;
    }

    // TODO: Implement A_TempestSpray
    // A_TempestSpray(360, 1024, 60, 80, 120, "TempestWandPuff3", "TempestWandTrail");
    void A_TempestSpray(double angle, double maxdist, double c, double d, double e, class<Actor> pufftype, class<Actor> trailtype) {}

    States {
        Spawn:
            FX16 ABC 3 Bright A_BlueSpark;
            FX16 C 0 Bright A_Countdown;
            Loop;
        Death:
            SWFX A 5 Bright;
            SWFX B 5 Bright A_TempestSpray(360, 1024, 60, 80, 120, "TempestSprayPuff", "TempestWandTrail");
            SWFX CDEF 5 Bright;
            Stop;
    }
}
