class SuperDemon : Actor {
    Default {
        Tag "$FN_SUPERDEMON";
        Health 750;
        Radius 32;
        Height 64;
        Speed 13;
        PainChance 40;
        Mass 500;
        MeleeRange 96;
        Monster;

        DropItem "CrystalVial", 51;
        DropItem "BagOfHolding", 8;

        SeeSound "sbtact";
        PainSound "sbtpai";
        DeathSound "sbtdth";
        ActiveSound "sbtact";
    }

    // 3 Fireball attack, called 1 time per sequence
    void A_SuperDemonAttack1(class<Actor> cls) {
        A_CustomMissile(cls, 62, 0, 0);
        A_CustomMissile(cls, 62, 0, -4.5);
        A_CustomMissile(cls, 62, 0, 4.5);
        A_StartSound("sbtatk");
    }

    // 2 Fireball attack, called 3 times per sequence
    void A_SuperDemonAttack2(class<Actor> cls, double min1, double max1, double min2, double max2) {
        A_CustomMissile(cls, 62, 0, frandom(min1, max1));
        A_CustomMissile(cls, 62, 0, frandom(min2, max2));
        A_StartSound("sbtatk");
    }

    States {
        Spawn:
            DEMN AA 10 A_Look;
            Loop;
        See:
            DEMN ABCD 4 A_Chase;
            Loop;
        Melee:
            DEMN G 6 A_FaceTarget;
            DEMN F 8 A_CustomMeleeAttack(8 * random(1, 8), "bitey", "bitey");
            DEMN E 6 A_FaceTarget;
            goto See;
        Missile:
            DEMN E 5 A_Jump(144, "MissileB");
            goto MissileA;
        MissileA:
            DEMN E 5 A_FaceTarget;
            DEMN F 6 A_FaceTarget;
            DEMN G 5 A_SuperDemonAttack1("SuperDemonFX1");
            goto See;
        MissileB:
            DEMN E 5 A_FaceTarget;
            DEMN F 6 A_FaceTarget;
            DEMN G 8 A_SuperDemonAttack2("SuperDemonFX1", 0, 0, -21, -9);
            DEMN E 5 A_FaceTarget;
            DEMN F 8 A_FaceTarget;
            DEMN G 8 A_SuperDemonAttack2("SuperDemonFX1", 0, 0, 9, 21);
            DEMN E 5 A_FaceTarget;
            DEMN F 8 A_FaceTarget;
            DEMN G 5 A_SuperDemonAttack2("SuperDemonFX1", -10, -4.5, 4.5, 10);
            goto See;
        Pain:
            DEMN E 4;
            DEMN E 4 A_Pain;
            goto See;
        Death:
            DEMN HI 6;
            DEMN J 6 A_Scream;
            DEMN K 6 A_NoBlocking;
            DEMN LMNO 6;
            DEMN P -1;
            Stop;
    }
}

class SuperDemonFX1 : SorcererFX1 {
    Default {
        Speed 15;
        Damage 8;
        DeathSound "sbthit";
    }
}