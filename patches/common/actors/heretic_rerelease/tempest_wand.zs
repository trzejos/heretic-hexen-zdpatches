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
        int dmg = basedmg + 3 * Random(1, randomDmg);
        A_RailAttack(0, 0, true, "", "", RGF_SILENT|RGF_NORANDOMPUFFZ|RGF_NOPIERCING, trailspread * 2, "", 0, 0, PLAYERMISSILERANGE, 0, traildist, 0, trailtype);
        let puff = LineAttack(Angle, PLAYERMISSILERANGE, BulletSlope(), dmg, 'Hitscan', pufftype, LAF_NORANDOMPUFFZ);
        if(puff)
            puff.ReactionTime = maxhops;
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

    static String DumpActor(Actor a) {
        if(a)
            return String.Format("%s:%p:[%.2f,%.2f]", a.GetClassName(), a, a.pos.x, a.pos.y);
        return "null";
    }

    static bool CheckTargets(Actor p, Actor mo) {
        Console.Printf("CheckTargets: %s | %s", DumpActor(p), DumpActor(mo));
        Console.Printf("Tracer: %s", DumpActor(p.tracer));
        if (mo == p.tracer)
            return true;
        if (p.master is 'TempestWandPuff')
            return TempestWandPuff.CheckTargets(p.master, mo);
        Console.Printf("Master: %s", DumpActor(p.master));
        if (mo == p.master)
            return true;
        Console.Printf("Next Target: %s", DumpActor(mo));
        Console.Printf("");
        return false;
    }

    Actor GetNextChain(double mindist, double maxdist) {
        double distance = maxdist;
        Actor result = null;
        let bti = BlockThingsIterator.Create(self, maxdist);
        while (bti.Next()) {
            let mo = bti.thing;
            if (!mo || !mo.bSolid || !mo.bShootable || mo.Health <= 0)
                continue;
            if (Distance2D(mo) > distance || Distance2D(mo) < mindist)
                continue;
            if (!CheckSight(mo, SF_IGNOREWATERBOUNDARY|SF_IGNOREVISIBILITY))
                continue;
            if (TempestWandPuff.CheckTargets(self, mo))
                continue;
            distance = Distance2D(mo);
            result = mo;
        }
        return result;
    }

    // A_TempestChain(0, 512, 50, 80, "swnzap", "TempestWandTrail", 16, 16);
    void A_TempestChain(double mindist, double maxdist, int mindmg, int maxdmg, String sound, class<Actor> trailtype, double trailspread, double traildist) {
        // End of the chain
        if (ReactionTime <= 0) return;

        // Find nearest actor within maxdist
        master = target;
        target = GetNextChain(mindist, maxdist);

        // End chain early if no next target could be found
        if (!target) return;

        // Play the sound
        double dist = Distance2D(target);
        int dmg = Random(mindmg, maxdmg);
        Angle = AngleTo(target);
        A_StartSound(sound);
        A_CustomRailgun(0, 0, "", "", RGF_SILENT, 1, trailspread * 2, "", 0, 0, dist, 0, traildist, 0, trailtype);
        let puff = SpawnPuff(GetClass(), target.pos, Angle, 0, 0, PF_HITTHING|PF_NORANDOMZ, target);
        target.DamageMobj(puff, self, dmg, 'Hitscan', DMG_INFLICTOR_IS_PUFF);
        puff.ReactionTime = ReactionTime - 1;
        puff.SetOrigin(puff.pos + (0, 0, max(target.height * 0.5, 32.0)), false);
    }

    States {
        Spawn:
        XDeath:
            FX16 GHI 4 Bright;
            FX16 J 4 Bright A_TempestChain(0, 512, 50, 80, "swnzap", "TempestWandTrail", 16, 16);
            FX16 KL 4 Bright;
            TNT1 A 75;
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

    // A_TempestSpray(360, 1024, 60, 80, 120, "TempestSprayPuff", "TempestWandTrail");
    void A_TempestSpray(double ang, double maxdist, int numrays, int mindmg, int maxdmg, class<Actor> pufftype, class<Actor> trailtype) {
        int dmg = Random(mindmg, maxdmg);
        FTranslatedLineTarget t;
        let originator = target;

        for (int i = 0; i < numrays; i++) {
            double a = Angle - ang / 2 + ang / numrays*i;
            AimLineAttack(a, maxdist, t);

            // Skip player and null targets
            if (originator == t.linetarget || !t.linetarget)
                continue;
            target = t.linetarget;
            
            Actor puff = SpawnPuff(pufftype, target.pos, t.angleFromSource, 0, 0, PF_NORANDOMZ, target);
            puff.SetOrigin(puff.pos + (0, 0, target.height/2), false);
            t.linetarget.DamageMobj(self, target, dmg, 'Hitscan', DMG_USEANGLE, t.angleFromSource);
            A_CustomRailgun(0, 0, "", "", RGF_SILENT, 1, 32, "", 0, 0, Distance3D(target), 0, 16, 0, trailtype);
        }

        target = originator;
    }

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
