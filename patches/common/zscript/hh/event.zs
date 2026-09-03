class HHItemHandler : HHHelperBase {
    override bool HandlePickup(Inventory item) {
        let result = Super.HandlePickup(item);

        if (!Owner)
            return result;
        if (!(Owner is 'PlayerPawn'))
            return result;

        if (item is 'Weapon') {
            // TODO: Weapon pieces are not directly added and not intercepted here
            if (!multiplayer && sv_weaponstay)
                item.Destroy();
        }

        return result;
    }
}

class HHEventHandler : EventHandler {
    void GiveItemHandler(int p) {
        PlayerPawn pawn = players[p].mo;

        if (!pawn) {
            Console.Printf("ERROR: Unable to find player number %d", p);
            return;
        }

        if (pawn.FindInventory('HHItemHandler'))
            return;
        pawn.GiveInventory('HHItemHandler', 0);
    }

    override void PlayerSpawned(PlayerEvent e) {
        GiveItemHandler(e.PlayerNumber);
    }

    override void PlayerRespawned(PlayerEvent e) {
        GiveItemHandler(e.PlayerNumber);
    }
}
