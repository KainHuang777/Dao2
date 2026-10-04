"""OFL derivatives for runtime text; originals remain untouched. fonttools==4.61.1.

Install into build/tool-deps; run with the bundled Python (no engine change).
--check fails when source text needs new glyphs; rerun without --check to rebuild.
"""
from pathlib import Path
import argparse
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'build/tool-deps'))
from fontTools import subset, version
from fontTools.ttLib import TTFont
if version != '4.61.1':
    raise RuntimeError('Expected fonttools==4.61.1 in build/tool-deps')

FONTS = [('SourceHanSansTW-VF.ttf', 'Dao2Sans-VF.ttf', 'Dao2 Sans'),
         ('NotoSerifTC-VF.ttf', 'Dao2Serif-VF.ttf', 'Dao2 Serif')]
FOLDER = ROOT / 'assets/fonts/runtime'
MANIFEST = FOLDER / 'manifest.json'

def corpus():
    paths = sorted(p for directory in ('src', 'content', 'scenes')
                   for p in (ROOT / directory).rglob('*')
                   if p.suffix in ('.gd', '.json', '.tscn', '.tres'))
    chars = set(range(0x20, 0x100))
    for path in paths:
        chars.update(ord(c) for c in path.read_text(encoding='utf-8-sig'))
    return chars, paths

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def inspect(source, output, chars):
    original, derived = TTFont(source), TTFont(output)
    wanted = chars & set(original.getBestCmap())
    missing = wanted - set(derived.getBestCmap())
    if missing:
        raise ValueError(f'{output.name}: missing glyphs {sorted(missing)}; regenerate fonts')
    if [(a.axisTag, a.minValue, a.defaultValue, a.maxValue) for a in original['fvar'].axes] != [(a.axisTag, a.minValue, a.defaultValue, a.maxValue) for a in derived['fvar'].axes]:
        raise ValueError('Variation axes changed')
    # Subsetting must preserve advance widths/vertical metrics and weight axes.
    for code in wanted:
        if original['hmtx'][original.getBestCmap()[code]] != derived['hmtx'][derived.getBestCmap()[code]]:
            raise ValueError(f'Advance changed U+{code:04X}')
    if original['hhea'].ascent != derived['hhea'].ascent or original['hhea'].descent != derived['hhea'].descent:
        raise ValueError('Vertical metrics changed')
    identity_ids = {1, 3, 4, 6, 16, 18, 21, 25}
    identity_ids.update(i.postscriptNameID for i in derived['fvar'].instances
                        if i.postscriptNameID != 0xFFFF)
    for entry in derived['name'].names:
        if entry.nameID in identity_ids and not entry.toUnicode().startswith('Dao2'):
            raise ValueError(f'Original identity remains in name ID {entry.nameID}')
    return {'source': source.relative_to(ROOT).as_posix(), 'source_sha256': sha(source),
            'output': output.relative_to(ROOT).as_posix(), 'output_sha256': sha(output),
            'source_bytes': source.stat().st_size, 'output_bytes': output.stat().st_size,
            'covered_codepoints': len(wanted), 'family': derived['name'].getDebugName(1),
            'axes': {a.axisTag: [a.minValue, a.defaultValue, a.maxValue] for a in derived['fvar'].axes},
            'unavailable_in_original': [f'U+{c:04X}' for c in sorted(chars - set(original.getBestCmap())) if c >= 0x20]}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    chars, paths = corpus()
    FOLDER.mkdir(parents=True, exist_ok=True)
    records = []
    for source_name, output_name, family in FONTS:
        source, output = ROOT / 'assets/fonts' / source_name, FOLDER / output_name
        if not args.check:
            font = TTFont(source, recalcTimestamp=False)
            options = subset.Options()
            options.name_IDs = ['*']
            options.name_languages = ['*']
            options.name_legacy = True
            options.notdef_glyph = True
            options.notdef_outline = True
            subsetter = subset.Subsetter(options=options)
            subsetter.populate(unicodes=chars)
            subsetter.subset(font)
            # Modified versions have distinct names, including localized records.
            names = {1: family, 3: family.replace(' ', '') + '-Runtime-1',
                     4: family + ' Regular', 6: family.replace(' ', '') + '-Regular',
                     16: family, 18: family, 21: family, 25: family.replace(' ', '')}
            for instance in font['fvar'].instances:
                if instance.postscriptNameID != 0xFFFF:
                    style = font['name'].getDebugName(instance.subfamilyNameID) or 'Regular'
                    names[instance.postscriptNameID] = family.replace(' ', '') + '-' + ''.join(c for c in style if c.isalnum())
            for entry in font['name'].names:
                if entry.nameID in names:
                    entry.string = names[entry.nameID].encode(entry.getEncoding())
            font.save(output)
        records.append(inspect(source, output, chars))
    if args.check:
        saved = json.loads(MANIFEST.read_text(encoding='utf-8'))
        if saved['fonts'] != records:
            raise ValueError('Font/source hash or coverage changed; regenerate manifest')
    else:
        report = {'generator': 'tools/subset_game_fonts.py', 'fonttools': version,
                  'license': 'SIL OFL 1.1; original copyright/licenses retained in assets/fonts',
                  'scope': 'Runtime source/content corpus plus Latin-1; arbitrary imported/custom strings may use fallback',
                  'fonts': records, 'input_files': [p.relative_to(ROOT).as_posix() for p in paths]}
        MANIFEST.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'ok': True, 'check_only': args.check, 'fonts': records}, ensure_ascii=True))

if __name__ == '__main__':
    main()
