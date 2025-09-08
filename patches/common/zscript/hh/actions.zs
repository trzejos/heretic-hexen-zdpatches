class HHRereleaseActions {
    static Actor HitActor(Actor src, Actor dst, class<Actor> pufftype, int dmg) {
        Actor inflictor = src;
        while (inflictor.bIsPuff && inflictor.target)
            inflictor = inflictor.target;

        let puff = src.SpawnPuff(pufftype, dst.pos + (0, 0, dst.Height/2), src.Angle, src.Angle, 0, PF_HITTHING|PF_NORANDOMZ, dst);
        dst.DamageMobj(puff, inflictor, dmg, 'Hitscan', DMG_INFLICTOR_IS_PUFF);
        return puff;
    }

    static void SpawnTrail(Vector3 src, Vector3 dst, class<Actor> trailtype, double spread, double dist) {
        let distance = (dst - src).Length();
        Vector3 unit = (dst - src).Unit();
        for (double d = 0; d < distance; d += dist) {
            let curpos = src + unit * d;
            Vector3 offset = (FRandom(-1, 1), FRandom(-1, 1), FRandom(-1, 1)) * spread/2;
            Actor.Spawn(trailtype, curpos + offset, ALLOW_REPLACE);
        }
    }

    static bool CheckChainHistory(Actor puff, Actor mo) {
        if (mo == puff.tracer || mo == puff.target)
            return true;
        if (puff.master && puff.master.bIsPuff)
            return CheckChainHistory(puff.master, mo);
        return false;
    }

    static Actor FindNearestActorInChain(Actor src, double mindist, double maxdist) {
        double distance = maxdist;
        Actor result = null;
        let bti = BlockThingsIterator.Create(src, maxdist);

        while (bti.Next()) {
            let mo = bti.thing;

            if (!mo || !mo.bShootable || mo.Health <= 0)
                continue;
            let d = src.Distance3D(mo);
            if (d > distance || d < mindist)
                continue;
            if (!src.CheckSight(mo, SF_IGNOREWATERBOUNDARY|SF_IGNOREVISIBILITY))
                continue;
            if (CheckChainHistory(src, mo))
                continue;

            distance = d;
            result = mo;
        }

        return result;
    }
}