
const SPECIAL_CLASS_SELECT = 124; // Show class selection menu
const SPECIAL_CLASS_CHANGE = 123; // Change class directly (0 = fighter, 1 = cleric, 2 = mage)
const SCRIPT_ID = 27000;

class Hexen2025PostProcessor : LevelPostProcessor {
    protected void Apply(Name checksum, String mapname) {
        for (int t = 0; t < GetThingCount(); t++) {
            switch(GetThingSpecial(t)) {
                case SPECIAL_CLASS_SELECT: {
                    SetThingSpecial(t, 80);
                    SetThingArgument(t, 0, SCRIPT_ID);
                    SetThingArgument(t, 1, 0);
                    SetThingArgument(t, 2, 0);
                    SetThingArgument(t, 3, 0);
                    SetThingArgument(t, 4, 0);
                    break;
                }
                case SPECIAL_CLASS_CHANGE: {
                    int classnum = GetThingArgument(t, 0);
                    SetThingSpecial(t, 80);
                    SetThingArgument(t, 0, SCRIPT_ID);
                    SetThingArgument(t, 1, 0);
                    SetThingArgument(t, 2, classnum + 1);
                    SetThingArgument(t, 3, 0);
                    SetThingArgument(t, 4, 0);
                    break;
                }
            }
        }

        for (int l = 0; l < level.Lines.Size(); l++) {
            Line line = level.Lines[l];
            switch (line.special) {
                case SPECIAL_CLASS_SELECT: {
                    line.special = 80;
                    line.args[0] = SCRIPT_ID;
                    line.args[1] = 0;
                    line.args[2] = 0;
                    break;
                }
                case SPECIAL_CLASS_CHANGE: {
                    int classnum = line.args[0];
                    line.special = 80;
                    line.args[0] = SCRIPT_ID;
                    line.args[1] = 0;
                    line.args[2] = classnum + 1;
                    break;
                }
            }
        }
    }
}