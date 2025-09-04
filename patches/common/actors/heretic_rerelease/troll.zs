class Troll : Actor {
    Default {
        Tag "$FN_TROLL";
        Health 500;
        Radius 24;
        Height 62;
        Speed 12;
        PainChance 32;
        MeleeRange 192;
        Mass 1000;
        Monster;

        SeeSound "trosit";
        ActiveSound "trosit";
        AttackSound "troswg";
        PainSound "tropai";
        DeathSound "trodth";

        +FLOORCLIP;
    }

    void A_TrollChargeStart(double speed, int duration, String sound) {
        if (!target) {
            return;
        }

        A_StartSound(sound);
        bSkullFly = true;
        A_FaceTarget();
        VelFromAngle(speed);
        special1 = duration;
    }

    void A_TrollCharge() {
        if (!target) {
            return;
        }

        if (special1 > 0) {
            special1--;
        } else {
            bSkullFly = false;
            SetStateLabel("See");
        }
    }

    void A_ClinkRushEX(double speed) {
        A_FaceTarget();
        VelFromAngle(speed);
    }

    void A_ClinkAttackEX(String hitsound, double range, int min, int max) {
        A_FaceTarget();
        int oldRange = MeleeRange;
        MeleeRange = range;
        A_CustomMeleeAttack(random(min, max), hitsound);
        MeleeRange = oldRange;
    }
    
    States {
        Spawn:
            TROL AB 10 A_Look;
            Loop;
        See:
            TROL ABCD 6 A_Chase;
            Loop;
        Missile:
            TROL E 0 A_TrollChargeStart(20, 35, "trochg");
            TROL E 1 A_TrollCharge;
            Wait;
        Melee:
            TROL F 6 A_ClinkRushEX(12);
            TROL G 6 A_ClinkRushEX(12);
            TROL H 8 A_ClinkAttackEX("trohit", 96, 10, 20);
            goto See;
        Pain:
            TROL F 2;
            TROL F 2 A_Pain;
            goto See;
        Death:
            TROL I 6;
            TROL I 6 A_Scream;
            TROL JK 8;
            TROL L 8 A_NoBlocking;
            TROL M -1;
            Stop;
    }
}