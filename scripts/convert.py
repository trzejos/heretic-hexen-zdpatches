#!/usr/bin/env python3

import lib.wadfile
import click
import yaml
import pathlib

@click.command()
@click.option('--path', help="Path to the rerelease install directory", required=True)
@click.option('--name', help="WAD file to convert", required=True)
@click.option('--out', help="Output directory to write patch to", required=True)
def main(path: str, name: str, out: str) -> int:
    if pathlib.Path(out).exists():
        raise RuntimeError(f"Output directory '{out}' already exists")
    with open(pathlib.Path(__file__).parent.joinpath('config.yaml'), 'r') as f:
        config = yaml.safe_load(f)
    wad = lib.wadfile.read_wad(path, name)
    raw_graphics = lib.wadfile.get_raw_graphics(wad, config[name])
    if name != 'hexdd.wad':
        exdefs = lib.wadfile.parse_exdefs(wad)
    else:
        exdefs = {}
    lib.wadfile.make_patch(wad, raw_graphics, exdefs, out)
    return 0

if __name__ == '__main__':
    exit(main())
