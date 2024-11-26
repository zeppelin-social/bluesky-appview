#!/usr/bin/env python

import argparse
import subprocess
from os.path import abspath, dirname, join

script_dir = dirname(abspath(__file__))
tsx_config = join(script_dir, 'comby-tsx.json')

angle_bracket_substs = [
    ('< ', '@lt@ '),
    ('<=', '@lt@='),
    ('=>', '@arrow@'),
    ('>=', '@gt@='),
    (' >', ' @gt@'),
]


def run_comby(src, match=None, replace=None, config=None):
    for orig, temp in angle_bracket_substs:
        src = src.replace(orig, temp)
    comby_cmd = ["comby", "-stdin", "-stdout", "-custom-matcher", tsx_config]
    if match or replace:
        comby_cmd.extend([match, replace])
    if config:
        comby_cmd.extend(['-config', config])
    run_result = subprocess.run(comby_cmd, input=src, capture_output=True, check=True, encoding='utf-8')
    result = run_result.stdout
    for orig, temp in reversed(angle_bracket_substs):
        result = result.replace(temp, orig)
    return result

def get_argument_parser():
    """builds an argument parser with the basic options (but not input and output files)"""
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--in-place', action='store_true', help='alter source file')
    parser.add_argument('-m', '--match', type=str, help='match pattern')
    parser.add_argument('-r', '--replace', type=str, help='replace pattern')
    parser.add_argument('-c', '--config', type=str, help='comby config file')
    return parser

if __name__ == '__main__':
    import sys
    parser = get_argument_parser()
    parser.add_argument('src_file', type=str, help='source filename')
    parser.add_argument('dest_file', type=str, nargs='?', help='dest filename')
    args = parser.parse_args()
    if args.in_place and args.dest_file:
       parser.error("specify either --in-place or dest_file, not both")
    if (args.match or args.replace) and args.config:
       parser.error("specify either (--match and --replace) or --config, not both")
    elif bool(args.match) != bool(args.replace):
       parser.error("specify both --match and --replace if using them")
    elif not args.config:
       parser.error("specify one of (--match and --replace) or --config")
    with open(args.src_file) as f:
       src = f.read()
    result = run_comby(src, config=args.config, match=args.match, replace=args.replace)
    if args.in_place or args.dest_file:
        with open(args.src_file if args.in_place else args.dest_file, 'w') as f:
            f.write(result)
    else:
        sys.stdout.write(result)

