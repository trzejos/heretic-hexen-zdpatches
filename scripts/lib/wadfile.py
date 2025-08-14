import enum
import io
from os import path
import pathlib
import omg
import deepmerge
import json
import PIL.Image

STATE_TRANSLATIONS = {
    # Weapon states
    'readystate': 'Ready',
    'selectstate': 'Select',
    'deselectstate': 'Deselect',
    'firestate': 'Fire',
    'holdstate': 'Hold',
    # Monster states
    'seestate': 'See',
    'painstate': 'Pain',
    'meleestate': 'Melee',
    'missilestate': 'Missile',
    # Generic states
    'activatestate': 'Active',
    'spawnstate': 'Spawn',
    'deathstate': 'Death',
}

def read_wad(root: str, name: str) -> omg.WadIO:
    root_path = pathlib.Path(root)
    full_path = root_path.joinpath(name)
    if not full_path.exists():
        raise RuntimeError(f"File {name} not found at '{root}'")
    wadio = omg.WadIO()
    wadio.open(str(full_path))
    return wadio

def get_palette(wad: omg.WadIO, lump: str = 'PLAYPAL') -> bytes:
    entry_index = wad.find(lump)
    if not entry_index:
        raise RuntimeError(f"Could not find palette named '{lump}'")
    with io.BytesIO(wad.read(lump)[0:3*256]) as palette_raw:
        palette_colors = []
        while palette_raw.tell() < 3*256:
            color = palette_raw.read(3)
            palette_colors.append((color[0], color[1], color[2]))
    return palette_colors

def get_raw_graphics(wad: omg.WadIO, lumps) -> dict[str, dict]:
    raw_graphics = {}
    for name, palette in lumps['raw_graphics'].items():
        raw_graphics[name] = {
            'raw': wad.read(name),
            'palette': get_palette(wad, palette),
        }
    return raw_graphics

def parse_exdefs(wad: omg.WadIO, options = [], lump='EXDEFS'):
    data = json.loads(wad.read(lump).decode())['data']
    includes = []
    if 'include' in data:
        includes = data['include']
        del data['include']
    for include in includes:
        if 'ifoption' not in include or include['ifoption'] in options:
            data = deepmerge.always_merger.merge(data, parse_exdefs(wad, options, include['lumpname']))
    return data

def make_patch(wad: omg.WadIO, raw_graphics, exdefs: dict, out: str):
    out_path = pathlib.Path(out)
    out_path.mkdir(parents=True, exist_ok=False)
    if raw_graphics:
        out_path.joinpath('graphics').mkdir()
        for name, graphic in raw_graphics.items():
            converted = convert_graphic(graphic['raw'], graphic['palette'])
            converted.save(out_path.joinpath(f"graphics/{name}.png"))
    if exdefs:
        if 'sounds' in exdefs:
            convert_sounds(exdefs['sounds'], out_path)
        if 'actors' in exdefs:
            zscript_actors = []
            for actor in exdefs['actors']:
                zscript_actors.extend(
                    convert_actor(
                        actor,
                        exdefs.get('states', []),
                        exdefs.get('pickups', []),
                        exdefs.get('artifacts', []),
                        exdefs.get('weapons', []),
                        exdefs.get('puffs', []),
                        out_path
                    )
                )

def convert_sounds(sounds: list, out: pathlib.Path):
    with open(out.joinpath('sndinfo.txt'), 'w') as sndinfo:
        for sound in sounds:
            if 'lump' in sound:
                sndinfo.write(f"{sound['name']} = {sound['lump']}\n")
            elif 'alias' in sound:
                sndinfo.write(f"$alias {sound['name']} {sound['alias']}\n")


def convert_graphic(raw, palette) -> PIL.Image.Image:
    height = 200
    width = int(len(raw)/height)
    image = PIL.Image.new('RGB', (width, height))
    for loc, color in enumerate(raw):
        x = int(loc % width)
        y = int(loc / width)
        image.putpixel((x, y), palette[color])
    return image

def dict_match(data: dict, search: dict) -> bool:
    for k, v in search.items():
        if k not in data or data[k] != v:
            return False
    return True

def dict_find(data: list[dict], search: dict) -> dict:
    for item in data:
        if dict_match(item, search):
            return item
    return {}

def convert_actor(
    actor: dict,
    state_table: list[dict],
    pickup_table: list[dict],
    artifact_table: list[dict],
    weapon_table: list[dict],
    puff_table: list[dict],
    out: pathlib.Path
):
    pickup = {}
    artifact = {}
    weapon = {}
    weapon2 = {}

    pickup = dict_find(pickup_table, {'name': actor.get('pickuptype')})
    if pickup.get('action') == 'A_PickupArtifact':
        artifact = dict_find(artifact_table, {'name': pickup['args'][0]})
    elif pickup.get('action') == 'A_PickupWeapon':
        weapon = dict_find(weapon_table, {'name': pickup['args'][0]})
    if weapon.get('weaponlevel2'):
        weapon2 = dict_find(weapon_table, {'name': weapon['weaponlevel2']})

    states, frames = state_search((actor, artifact, weapon), state_table)
    actors = [{
        'name': actor['name'],
        'base': actor.get('inherits'),
        'ednum': actor.get('doomednum'),
        'properties': {},
        'flags': [],
        'states': states,
        'frames': frames,
    }]
    if weapon2:
        w2_states, w2_frames = state_search((weapon2,), state_table)
        actors.append({
            'name': weapon2['name'],
            'base': actor['name'],
            'ednum': None,
            'properties': {},
            'flags': [],
            'states': w2_states,
            'frames': w2_frames,
        })
    return actors

def state_search(data_dicts, state_table) -> tuple[dict[str, str], list[dict]]:
    states = {}
    frames = []
    old_frames = set()
    for data in data_dicts:
        for key, value in data.items():
            if not key.endswith('state'):
                continue
            states[STATE_TRANSLATIONS[key]] = value
            result = get_state_frames(state_table, value, old_frames)
            frames.extend(result[0])
            old_frames.update(result[1])
    return states, frames

def get_frame_labels(frames: list[dict]) -> set[str]:
    return {frame['label'] for frame in frames}

def get_state_frames(state_table: list[dict], label: str, old_frames: set[str] = set(), offset: int = 0) -> list[dict]:
    index = -1
    for idx, frame in enumerate(state_table):
        if frame['name'] == label:
            index = idx
            break
    if index == -1:
        return [], old_frames
    frame = state_table[index + offset]
    if frame['name'] in old_frames:
        return [], old_frames
    old_frames.add(frame['name'])
    frames = [{
        'label': frame['name'],
        'sprite': frame['sprite'],
        'frame': frame['frame'][0],
        'bright': frame['frame'].endswith('!'),
        'tics': frame['tics'],
        'next': frame['next'],
        'action': (frame.get('action'), frame.get('args', []))
    }]

    if frame['next'] == '@next':
        result = get_state_frames(state_table, label, old_frames, offset + 1)
        old_frames.update(result[1])
        frames.extend(result[0])
    elif not frame['next'].startswith('@'):
        result = get_state_frames(state_table, frame['next'], old_frames)
        old_frames.update(result[1])
        frames.extend(result[0])
    if frame.get('action') == 'A_RandomJump':
        result = get_state_frames(state_table, frame['args'][0], old_frames)
        old_frames.update(result[1])
        frames.extend(result[0])
    elif 'Jump' in frame.get('action', ''):
        print(frame)
    return frames, old_frames
    