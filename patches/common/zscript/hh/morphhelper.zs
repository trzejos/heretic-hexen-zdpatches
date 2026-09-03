class HHMorphHelper play {
    static int MorphPlayer(int playernum, int classnum) {
        // Make sure we have a valid player number and they are in game
        if (playernum < 0 || playernum >= MAXPLAYERS)
            return 0;
        if (!PlayerInGame[playernum])
            return 0;

        // Make sure the player has a pawn and is alive
        let player = players[playernum];
        if (!player.mo || player.health <= 0)
            return 0;

        // Get new class number
        let newclassnum = (classnum - 1) % PlayerClasses.Size();
        if (classnum == 0)
            // Cycle based on current class if classnum was 0
            newclassnum = (player.CurrentPlayerClass + 1) % PlayerClasses.Size();

        // Abort early if we are about to switch to the same class
        if (newclassnum == player.CurrentPlayerClass)
            return 0;

        // Create new pawn and teleport fog
        let oldPawn = player.mo;
        let newPawn = PlayerPawn(Actor.Spawn(PlayerClasses[newclassnum].Type, oldPawn.Pos, NO_REPLACE));
        if (!newPawn) return 0;
        Actor.Spawn('TeleportFog', oldPawn.Pos, NO_REPLACE);

        TransferProperties(oldPawn, newPawn, newclassnum);
        TransferInventory(oldPawn, newPawn);

        // Cleanup
        oldPawn.Destroy();
        let prettyName = StringTable.Localize(PlayerPawn.GetPrintableDisplayName(PlayerClasses[newclassnum].Type));
        newPawn.A_Print("Changed class to "..prettyName);

        return 1;
    }

    static void TransferProperties(PlayerPawn oldPawn, PlayerPawn newPawn, int newclassnum) {
        let player = oldPawn.player;

        // Transfer player/camera
        newPawn.Player = player;
        player.Mo = newPawn;
        player.Camera = newPawn;
        player.Cls = newPawn.GetClassName();
        player.CurrentPlayerClass = newclassnum;
        player.ViewHeight = newPawn.ViewHeight;
        oldPawn.player = null;

        // Transfer actor pointers
        ThinkerIterator ti = ThinkerIterator.Create();
        Actor mo;
        while (mo = Actor(ti.Next())) {
            if (mo.Target == oldPawn)
                mo.Target = newPawn;
            if (mo.Tracer == oldPawn)
                mo.Tracer = newPawn;
            if (mo.Master == oldPawn)
                mo.Master = newPawn;
            if (!mo.bIsMonster)
                continue;
            if (mo.LastHeard == oldPawn)
                mo.LastHeard = newPawn;
            if (mo.LastEnemy == oldPawn)
                mo.LastEnemy = newPawn;
            if (mo.LastLookActor == oldPawn)
                mo.LastLookActor = newPawn;
        }

        // Transfer properties
        newPawn.Translation = oldPawn.Translation;
        newPawn.Vel = oldPawn.Vel;
        newPawn.Angle = oldPawn.Angle;
        newPawn.Pitch = oldPawn.Pitch;
        newPawn.Target = oldPawn.Target;
        newPawn.Tracer = oldPawn.Tracer;
        newPawn.Master = oldPawn.Master;
        newPawn.FriendPlayer = oldPawn.FriendPlayer;
        newPawn.DesignatedTeam = oldPawn.DesignatedTeam;
        newPawn.Score = oldPawn.Score;
        newPawn.Health = oldPawn.Health;

        // Transfer TID if applicable
        if (oldPawn.TID) {
            newPawn.ChangeTid(oldPawn.TID);
            oldPawn.ChangeTid(0);
        }
    }

    static void TransferInventory(PlayerPawn oldPawn, PlayerPawn newPawn) {
        HHWeaponTracker oldWeapons = new('HHWeaponTracker');
        HHWeaponHolderTracker oldWeaponPieces = new('HHWeaponHolderTracker');
        oldWeapons.key = oldPawn.GetClassName();
        oldWeaponPieces.key = oldPawn.GetClassName();
        HHWeaponTrackerGroup newWeaponTrackers = HHWeaponTrackerGroup(Actor.Spawn('HHWeaponTrackerGroup'));
        HHWeaponHolderTrackerGroup newWeaponPieceTrackers = HHWeaponHolderTrackerGroup(Actor.Spawn('HHWeaponHolderTrackerGroup'));

        let newBasicArmor = BasicArmor(Actor.Spawn(Actor.GetBasicArmorClass()));
        let newHexenArmor = HexenArmor(Actor.Spawn(Actor.GetHexenArmorClass()));
        newPawn.AddInventory(newBasicArmor);
        newPawn.AddInventory(newHexenArmor);

        // Copy old inventory
        for(let ii = oldPawn.Inv; ii != null; ii = ii.Inv) {
            String itype = ii.GetClassName();
            class<Actor> c = itype;

            // Convert flechettes to class specific type
            if (c is 'ArtiPoisonBag')
                itype = newPawn.FlechetteType.GetClassName();

            // Store found weapons
            if (c is 'Weapon') {
                oldWeapons.Collect(itype);
                continue;
            }

            // Store found weapon pieces
            if (c is 'WeaponHolder') {
                oldWeaponPieces.Collect(WeaponHolder(ii));
                continue;
            }

            if (c is 'BasicArmor') {
                CopyBasicArmor(BasicArmor(ii), newBasicArmor);
                continue;
            }

            if (c is 'HexenArmor') {
                CopyHexenArmor(newPawn, HexenArmor(ii), newHexenArmor);
                continue;
            }

            // Restore Trackers
            if (c is 'HHWeaponTrackerGroup')
                newWeaponTrackers.ImportTrackers(HHWeaponTrackerGroup(ii));
            if (c is 'HHWeaponHolderTrackerGroup')
                newWeaponPieceTrackers.ImportTrackers(HHWeaponHolderTrackerGroup(ii));
            if (c is 'HHTrackerBase')
                continue;

            newPawn.GiveInventory(itype, ii.Amount);
        }

        // Restore previously found weapons
        newWeaponTrackers.AddTracker(oldWeapons);
        if (newWeaponTrackers.CallTryPickup(newPawn))
            newWeaponTrackers.GiveWeapons(newPawn);
        else
            newWeaponTrackers.Destroy();

        // Restore WeaponHolders
        newWeaponPieceTrackers.AddTracker(oldWeaponPieces);
        if (newWeaponPieceTrackers.CallTryPickup(newPawn))
            newWeaponPieceTrackers.GiveWeaponHolders(newPawn);
        else
            newWeaponPieceTrackers.Destroy();
        
        bool foundweapon = false;
        for(let di = newPawn.GetDropItems(); di != null; di = di.Next) {
            // Add missing starting inventory
            if (!newPawn.FindInventory(di.Name))
                newPawn.GiveInventory(di.Name, di.Amount);

            // Switch to a valid weapon
            class<Actor> c = di.Name;
            if (c is 'Weapon') {
                if (!foundweapon) {
                    foundweapon = true;
                    ScriptUtil.SetWeapon(newPawn, di.Name);
                }
            }
        }
    }

    static void CopyBasicArmor(BasicArmor oldArmor, BasicArmor newArmor) {
        newArmor.SavePercent      = oldArmor.SavePercent;
        newArmor.Amount           = oldArmor.Amount;
        newArmor.MaxAbsorb        = oldArmor.MaxAbsorb;
        newArmor.Icon             = oldArmor.Icon;
        newArmor.BonusCount       = oldArmor.BonusCount;
        newArmor.ArmorType        = oldArmor.ArmorType;
        newArmor.ActualSaveAmount = oldArmor.ActualSaveAmount;
        newArmor.MaxAllowedAmount = oldArmor.MaxAllowedAmount;
        newArmor.bAltSemantics    = oldArmor.bAltSemantics;
        newArmor.AbsorbCount      = oldArmor.AbsorbCount;
        newArmor.MaxFullAbsorb    = oldArmor.MaxFullAbsorb;
    }

    static void CopyHexenArmor(PlayerPawn p, HexenArmor oldArmor, HexenArmor newArmor) {
        newArmor.Slots[4] = p.HexenArmor[0];
        for (int i = 0; i < 4; i++) {
            newArmor.SlotsIncrement[i] = p.HexenArmor[i+1];
            newArmor.Slots[i] = oldArmor.Slots[i] * newArmor.SlotsIncrement[i] / oldArmor.SlotsIncrement[i];
        }
    }
}

class HHTrackerBase : Inventory {
    Default {
        +INVENTORY.QUIET
        +INVENTORY.UNDROPPABLE
        +INVENTORY.PERSISTENTPOWER
        +INVENTORY.KEEPDEPLETED
    }
}

class HHWeaponTrackerGroup : HHTrackerBase {
    Map<Name, HHWeaponTracker> trackers;

    void AddTracker(HHWeaponTracker wt) {
        trackers.Insert(wt.key, wt);
    }

    void ImportTrackers(HHWeaponTrackerGroup wtg) {
        foreach(wt : wtg.trackers)
            AddTracker(wt);
    }

    void GiveWeapons(PlayerPawn pawn) {
        if (!trackers.CheckKey(pawn.GetClassName()))
            return;
        trackers.Get(pawn.GetClassName()).GiveWeapons(pawn);
    }
}

class HHWeaponTracker play {
    Name key;
    Array<Name> collectedWeapons;

    void Collect(Name w) {
        if (collectedWeapons.Find(w) == collectedWeapons.Size())
            collectedWeapons.Push(w);
    }

    void GiveWeapons(PlayerPawn pawn) {
        for (int i = 0; i < collectedWeapons.Size(); i++) {
            if (!pawn.FindInventory(collectedWeapons[i]))
                pawn.GiveInventory(collectedWeapons[i], 1);
        }
    }
}

class HHWeaponHolderTrackerGroup : HHTrackerBase {
    Map<Name, HHWeaponHolderTracker> trackers;

    void AddTracker(HHWeaponHolderTracker wt) {
        trackers.Insert(wt.key, wt);
    }

    void ImportTrackers(HHWeaponHolderTrackerGroup wtg) {
        foreach(wt : wtg.trackers)
            AddTracker(wt);
    }

    void GiveWeaponHolders(PlayerPawn pawn) {
        if (!trackers.CheckKey(pawn.GetClassName()))
            return;
        trackers.Get(pawn.GetClassName()).GiveWeaponHolders(pawn);
    }
}

class HHWeaponHolderTracker play {
    Name key;
    Map<Name, int> holders;

    void Collect(WeaponHolder wh) {
        holders.Insert(wh.PieceWeapon.GetClassName(), wh.PieceMask);
    }

    void GiveWeaponHolders(PlayerPawn pawn) {
        foreach(weap, mask : holders) {
            let h = WeaponHolder(Actor.Spawn('WeaponHolder'));
            class<Weapon> cls = weap;
            h.PieceWeapon = cls;
            h.PieceMask = mask;
            if (!h.CallTryPickup(pawn))
                h.Destroy();
        }
    }
}
