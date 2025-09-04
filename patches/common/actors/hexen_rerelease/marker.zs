class MapMarkerGeneric : MapMarker {
	Default {
		//$Title "Map Marker"
		//$Category "Other"
	}

    States {
        Spawn:
            MARK A -1;
            Stop;
    }
    
    override void Activate (Actor activator) {
        bDormant = false;
    }

    override void Deactivate (Actor activator) {
        bDormant = true;
    }
}
