class Draugr : Actor {
    Default {
        Tag "$FN_MUMMY2";
        Health 60;
        ReactionTime 12;
        Radius 16;
        Height 62;
        Mass 100;
        Speed 10;
        PainChance 192;
        Monster;

        SeeSound "mum2sit";
        PainSound "mum2pai";
        DeathSound "mum2dth";
        ActiveSound "mum2sit";

        +FLOORCLIP;
    }

    States {
        Spawn:
            MUM2 AB 10 A_Look;
            Loop;
        See:
            MUM2 AABBCCDD 2 A_Chase;
            Loop;
        Missile:
            MUM2 E 5 A_FaceTarget;
            MUM2 F 5 bright A_FaceTarget;
            MUM2 G 10 bright A_SpawnProjectile("DraugrFX1");
            goto See;
        Pain:
            MUM2 E 2;
            MUM2 E 2 A_Pain;
            goto See;
        Death:
            MUM2 H 6;
            MUM2 I 6 A_Scream;
            MUM2 JK 6;
            MUM2 L 6 A_NoBlocking;
            MUM2 M 6;
            MUM2 N -1;
            Stop;
    }
}

class DraugrFX1 : Actor {
    Default {
        Projectile;

        Radius 8;
        Height 14;
        Speed 14;
        Damage 2;
        Mass 100;
        SeeSound "mum2atk";
        DeathSound "maghit";
    }

    States {
        Spawn:
            PSKL A 5 Bright; // A_StartSound("mum2atk");
            PSKL BCB 5 Bright;
            Loop;
        Death:
            PSKL D 5 Bright A_Scream;
            PSKL EFG 5 Bright;
            Stop;
    }
}
