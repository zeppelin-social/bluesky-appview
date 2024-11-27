#!/usr/bin/env python

import argparse
import subprocess
from os.path import abspath, dirname, join
import comby_tsx
import re

script_dir = dirname(abspath(__file__))
replace_svg_contents_config = join(script_dir, 'comby-replace-svg-contents.toml')

def get_svg_inner(src):
    # this could be done with more finesse
    return src[src.find(">")+1:src.rfind("<")]

tag_initial = re.compile("[<]/?[a-z][a-z]*")
svg_inner_block = re.compile("@SVG_INNER_START@.*@SVG_INNER_END@", re.DOTALL)
style_re = re.compile('style="[^"]*"')

def hyphen_to_camelcase(key):
    key_parts = key.split('-')
    return ''.join([key_parts[0]] + [part.title() for part in key_parts[1:]])

def style_to_attribs(stylestr):
    stylestr_parts = stylestr.split(';') if stylestr else []
    key_value_pairs = [style_attrib.split(':', 1) if ':' in style_attrib else (style_attrib, '') for style_attrib in stylestr_parts]
    key_value_pairs = [(key, value[1:-1] if value.startswith("'") and value.endswith("'") else value) for key, value in key_value_pairs]
    key_value_pairs = [(hyphen_to_camelcase(key), value) for key, value in key_value_pairs if key and not key.startswith('-inkscape')]
    return ' '.join(f'{key}="{value}"' for key, value in key_value_pairs)

def svg_to_tsx(src):
    # this could be done with more finesse
    tags = set(tag_initial.findall(src))
    for tag in tags:
        new_tag = tag[:3].upper() + tag[3:] if '/' in tag else tag[:2].upper()+tag[2:]
        src = src.replace(tag, new_tag)
    stylestrs = set(style_re.findall(src))
    for stylestr in stylestrs:
        new_styles = style_to_attribs(stylestr[7:-1])
        src = src.replace(stylestr, new_styles)
    return src, [tag[1:2].upper() + tag[2:] for tag in tags if '/' not in tag]

def adjust_svg_and_import(src, svg, config_file=replace_svg_contents_config):
    svg_inner = get_svg_inner(svg)
    tsx_svg_inner, tsx_tags = svg_to_tsx(svg_inner)
    result = comby_tsx.run_comby(src, config=config_file)
    inner_parts = svg_inner_block.findall(result)
    for inner_part in inner_parts:
        result = result.replace(inner_part, '@SVG_INNER@')
    imported_svg_objects = []
    search_result = result[result.rfind('@SVG_TAGS@'):]
    import_replacements = {}
    for imported_tags in re.findall("[{][^}]*@SVG_TAGS?@[}]", result):
        imported_tags = imported_tags.strip('{}').replace("@SVG_TAGS@", "")
        used_tags = []
        for existing_tag in imported_tags.split(','):
            existing_tag = existing_tag.strip()
            if re.findall(f"\\b{existing_tag}\\b", search_result):
                used_tags.append(existing_tag)
        import_replacements[imported_tags] = ', '.join(used_tags)
        imported_svg_objects.extend(tag.strip() for tag in used_tags if tag.strip())
    tsx_tags = [tag for tag in tsx_tags if tag not in imported_svg_objects]
    new_tags_str = ', '.join(tsx_tags)
    result = result.replace('@SVG_INNER@', tsx_svg_inner).replace('@SVG_TAGS@', new_tags_str)
    for import_original, import_new in import_replacements.items():
        result = result.replace(import_original, import_new)
    return result

if __name__ == '__main__':
    import argparse
    import sys
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--in-place', action='store_true', help='alter source file')
    parser.add_argument('-c', '--config', default=replace_svg_contents_config, type=str, help='comby config file')
    parser.add_argument('tsx_file', type=str, help='source .tsx filename')
    parser.add_argument('svg_file', type=str, help='source .svg filename')
    parser.add_argument('dest_file', type=str, nargs='?', help='dest filename')
    args = parser.parse_args()
    if args.in_place and args.dest_file:
       parser.error("specify either --in-place or dest_file, not both")
    with open(args.tsx_file) as f:
       src = f.read()
    with open(args.svg_file) as f:
       svg = f.read()
    result = adjust_svg_and_import(src, svg, args.config)
    if args.in_place or args.dest_file:
        with open(args.src_file if args.in_place else args.dest_file, 'w') as f:
            f.write(result)
    else:
        sys.stdout.write(result)

