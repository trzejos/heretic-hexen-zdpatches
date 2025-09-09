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

    // A_FireTempestWandPL1(50, 8, 3, "TempestPuff", "TempestTrail", 16, 16);
    action void A_FireTempestWandPL1(int basedmg, int randomdmg, int maxhops, class<Actor> pufftype, class<Actor> trailtype, double trailspread, double traildist) {
        MBF21_ConsumeAmmo(0);
        int dmg = basedmg + 3 * Random(1, randomDmg);
        FTranslatedLineTarget t;
        let puff = LineAttack(Angle, PLAYERMISSILERANGE, BulletSlope(), dmg, 'Hitscan', pufftype, LAF_NORANDOMPUFFZ, t);
        if(puff) {
            HHRereleaseActions.SpawnTrail(pos + (0, 0, Height/2), puff.pos, trailtype, trailspread, traildist);
            puff.ReactionTime = maxhops;
        }
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
            SWND D 4 Bright A_FireTempestWandPL1(50, 8, 3, "TempestPuff", "TempestTrail", 16, 16);
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
            SWND F 5 Bright MBF21_WeaponProjectile("TempestBomb", 0, 0, 0, 0);
            SWND C 5 Bright;
            SWND B 5 Bright A_ReFire;
            goto Ready;
    }
}

class TempestTrail : Actor {
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

class TempestPuff : Actor {
    Default {
        Radius 20;
        Height 16;
        ReactionTime 1;

        SeeSound "swnhit";
        AttackSound "swnmis";

        +NOBLOCKMAP;
        +NOGRAVITY;
        +ALWAYSPUFF;
        +PUFFONACTORS;
        +PUFFGETSOWNER;
        +HITTRACER;
    }

    // A_TempestChain(0, 512, 50, 80, "swnzap", "TempestTrail", 16, 16);
    void A_TempestChain(double mindist, double maxdist, int mindmg, int maxdmg, String sound, class<Actor> trailtype, double trailspread, double traildist) {
        // End of the chain
        if (ReactionTime <= 0) return;

        // Find nearest actor within maxdist
        let next = HHRereleaseActions.FindNearestActorInChain(self, mindist, maxdist);

        // End chain early if no next target could be found
        if (!next) return;

        // Do the attack
        A_StartSound(sound);
        let puff = HHRereleaseActions.HitActor(self, next, GetClass(), Random(mindmg, maxdmg));
        if (puff) {
            HHRereleaseActions.SpawnTrail(self.pos, puff.pos, trailtype, trailspread, traildist);
            puff.ReactionTime = ReactionTime - 1;
        }
    }

    States {
        Spawn:
        XDeath:
            FX16 GHI 4 Bright;
            FX16 J 4 Bright A_TempestChain(0, 512, 50, 80, "swnzap", "TempestTrail", 16, 16);
            FX16 KL 4 Bright;
            Stop;
        Crash:
            FX18 OPQRS 4 Bright;
            Stop;
    }
}

class TempestBombPuff : TempestPuff {
    States {
        Spawn:
        XDeath:
            SWFX GHIJK 4 Bright;
            Stop;
    }
}

class TempestBomb : Sorcerer2FX1 {
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

    // A_TempestSpray(360, 1024, 60, 80, 120, "TempestBombPuff", "TempestTrail");
    void A_TempestSpray(double ang, double maxdist, int mindmg, int maxdmg, int numrays, class<Actor> pufftype, class<Actor> trailtype) {
        FTranslatedLineTarget t;
        RadiusAttack(target, ExplosionDamage, ExplosionRadius, 'Normal', RADF_CIRCULAR);

        for (int i = 0; i < numrays; i++) {
            double a = Angle - ang / 2 + ang / numrays*i;
            AimLineAttack(a, maxdist, t);

            // Skip player and null targets
            if (target == t.linetarget || !t.linetarget)
                continue;
            int dmg = Random(mindmg, maxdmg);
            let puff = HHRereleaseActions.HitActor(self, t.linetarget, pufftype, dmg);
            HHRereleaseActions.SpawnTrail(self.pos, puff.pos, trailtype, 16, 16);
        }
    }

    States {
        Spawn:
            FX16 ABC 3 Bright A_BlueSpark;
            FX16 C 0 Bright A_Countdown;
            Loop;
        Death:
            SWFX A 5 Bright;
            SWFX B 5 Bright A_TempestSpray(360, 1024, 60, 80, 120, "TempestBombPuff", "TempestTrail");
            SWFX CDEF 5 Bright;
            Stop;
    }
}
