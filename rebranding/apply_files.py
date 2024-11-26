#!/usr/bin/env python

import argparse
import configparser
import logging
from os.path import join
import shutil
import yaml
import replace_svg_in_tsx
import re

env_parser = configparser.RawConfigParser(delimiters=('=',), comment_prefixes=('#',), inline_comment_prefixes=('#',))
env_parser.optionxform = lambda option: option
dummy_header_prefix = f'[{env_parser.default_section}]\n'

def read_env(filename):
   with open(filename, 'r') as f:
       env_src = f.read()
   env_parser.read_string(dummy_header_prefix + env_src)
   return dict(env_parser[env_parser.default_section].items())

def replace_env(src, env):
    """This replaces ${keyname} with values in src wherever keyname is defined in env, but otherwise leaves unchanged"""
    for key, value in sorted(env.items()):
        src = src.replace('${%s}' % key, value)
    return src

def copy_files(config, env, dry_run=False):
    def get_config(node, key):
        value = node.get(key)
        return replace_env(value, env) if value else value
    for copy_config in config:
        src_dir = get_config(copy_config, 'src_dir')
        dest_dir = get_config(copy_config, 'dest_dir')
        copy_files = copy_config.get('files') or []
        logging.info(f"Copying {len(copy_files)} files from {src_dir} to {dest_dir}")
        for filename_def in copy_files:
            filename = replace_env(filename_def, env)
            src_filename = join(src_dir, filename)
            dest_filename = join(dest_dir, filename)
            logging.info(f"Copying {filename}")
            if not dry_run:
                shutil.copy2(src_filename, dest_filename)

width_height_re = re.compile('width="[^"]*" height="[^"]*"')
view_box_re = re.compile('viewBox="[^"]*"')

def replace_svg_in_html_files(config, env, dry_run=False):
    def get_config(node, key, default=None):
        value = node.get(key, default)
        return replace_env(value, env) if value else value
    for subst_config in config:
        src_dir = get_config(subst_config, 'src_dir')
        dest_dir = get_config(subst_config, 'dest_dir')
        file_substs = subst_config.get('file_substs') or []
        logging.info(f"Substituting {len(file_substs)} files from {src_dir} to {dest_dir}")
        for file_subst_def in file_substs:
            src_filename = get_config(file_subst_def, 'dest')
            svg_filename = get_config(file_subst_def, 'src')
            view_box = get_config(file_subst_def, 'view_box')
            src_pathname = join(dest_dir, src_filename)
            svg_pathname = join(src_dir, svg_filename)
            logging.info(f"Substituting {svg_filename} into {src_filename}")
            with open(src_pathname) as f:
                src = f.read()
            with open(svg_pathname) as f:
                svg = f.read()
                if view_box:
                    for width_height in width_height_re.findall(svg):
                        svg = svg.replace(width_height, f'viewBox="{view_box}"')
            result = src[:src.find('<svg')] + svg + src[src.find('</svg>')+6:]
            if not dry_run:
                with open(src_pathname, 'w') as f:
                    f.write(result)

def replace_svg_in_tsx_files(config, env, dry_run=False):
    def get_config(node, key):
        value = node.get(key)
        return replace_env(value, env) if value else value
    for subst_config in config:
        src_dir = get_config(subst_config, 'src_dir')
        dest_dir = get_config(subst_config, 'dest_dir')
        file_substs = subst_config.get('file_substs') or []
        logging.info(f"Substituting {len(file_substs)} files from {src_dir} to {dest_dir}")
        for file_subst_def in file_substs:
            src_filename = get_config(file_subst_def, 'dest')
            svg_filename = get_config(file_subst_def, 'src')
            view_box = get_config(file_subst_def, 'view_box')
            pre_replace = file_subst_def.get('pre_replace', [])
            post_replace = file_subst_def.get('post_replace', [])
            src_pathname = join(dest_dir, src_filename)
            svg_pathname = join(src_dir, svg_filename)
            logging.info(f"Substituting {svg_filename} into {src_filename}")
            with open(src_pathname) as f:
                src = f.read()
            with open(svg_pathname) as f:
                svg = f.read()
            for pre_replace_def in pre_replace:
                find_re, repl = pre_replace_def['find'], pre_replace_def['replace']
                svg = re.sub(find_re, repl, svg)
            result = replace_svg_in_tsx.adjust_svg_and_import(src, svg)
            if view_box:
                for view_box_attr in view_box_re.findall(result):
                    result = result.replace(view_box_attr, f'viewBox="{view_box}"')
            for post_replace_def in post_replace:
                find_re, repl = post_replace_def['find'], post_replace_def['replace']
                result = re.sub(find_re, repl, result)
            if not dry_run:
                with open(src_pathname, 'w') as f:
                    f.write(result)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', type=str, required=True, help="Config file")
    parser.add_argument('-e', '--env-file', type=str, action='append', default=[], help="Env file (can specify multiple)")
    parser.add_argument('-n', '--dry-run', action='store_true', default=False, help="Don't actually copy")
    parser.add_argument('-l', '--loglevel', type=str, default='INFO', help="log level")
    args = parser.parse_args()
    if args.loglevel:
        logging.getLogger().setLevel(args.loglevel)
    with open(args.config) as config_file:
        config = yaml.safe_load(config_file)
    env = {}
    for env_file in args.env_file:
        env.update(read_env(args.env_file))
    copy_files(config.get('copy_files', []), env, dry_run=args.dry_run)
    replace_svg_in_html_files(config.get('svg_html_subst', []), env, dry_run=args.dry_run)
    replace_svg_in_tsx_files(config.get('svg_tsx_subst', []), env, dry_run=args.dry_run)


