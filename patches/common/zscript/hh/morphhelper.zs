class HHMorphHelper play {
    static void TransferProperties(PlayerPawn oldPawn, PlayerPawn newPawn) {
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
        // Copy old inventory
        for(let ii = oldPawn.Inv; ii != null; ii = ii.Inv) {
            String itype = ii.GetClassName();
            class<Actor> c = itype;

            // Convert flechettes to class specific type
            if (c is 'ArtiPoisonBag')
                itype = newPawn.FlechetteType.GetClassName();

            // Store found weapons
            if (c is 'Weapon')
                // TODO: Somehow track weapons which have been picked up
                continue;

            // Store found weapon pieces
            if (c is 'WeaponHolder')
                // TODO: Track weapon pieces
                // https://github.com/UZDoom/UZDoom/blob/trunk/wadsrc/static/zscript/actors/inventory/weaponpiece.zs
                continue;
            if (c is 'BasicArmor')
                // TODO: Figure out armor
                // https://github.com/UZDoom/UZDoom/blob/trunk/wadsrc/static/zscript/actors/inventory/armor.zs
                continue;
            if (c is 'HexenArmor')
                continue;
            newPawn.GiveInventory(itype, ii.Amount);
        }
        
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

        TransferProperties(oldPawn, newPawn);
        TransferInventory(oldPawn, newPawn);

        // Cleanup
        oldPawn.Destroy();
        let prettyName = StringTable.Localize(PlayerPawn.GetPrintableDisplayName(PlayerClasses[newclassnum].Type));
        newPawn.A_Print("Changed class to "..prettyName);

        return 1;
    }
}