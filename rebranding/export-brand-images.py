#!/usr/bin/env python

import logging
import os
import subprocess
import sys
from os.path import abspath, dirname, exists, join
import compactify_svg

src_dir = dirname(abspath(__file__))
# if exist "{src_dir}\script-env.cmd" call "{src_dir}\script-env.cmd"
exe_name = 'inkscape.com' if sys.platform.startswith('win') else 'inkscape'
magick_prefix = ["magick"] if sys.platform.startswith('win') else []

def inkscape_convert(src_path, src_id, target_dir, target_ext, id_only=False):
    exportargs = []
    if target_ext == "svg":
        exportargs.append('--export-plain-svg')
    if id_only:
        exportargs.extend([
            f'--actions=select:{src_id};clone-unlink;export-text-to-path',
            '--export-id-only',
        ])
    logging.info(f"Extracting {src_path}:{src_id} to {target_dir}/{src_id}.{target_ext}")
    subprocess.run([exe_name, f"--export-type={target_ext}", f"--export-id={src_id}"] + exportargs + [f"--export-filename={join(target_dir, src_id)}.{target_ext}", src_path])

def wait_for_file(look_for_file, max_looks=20):
    t = 0
    while t < max_looks:
        if os.exist(look_for_file):
            return True
        time.sleep(1)
        t += 1
    return os.exist(look_for_file)

def export_images(src, target_dir):
    inkscape_convert(src, 'splash-dark', target_dir, 'png')
    inkscape_convert(src, 'splash', target_dir, 'png')
    inkscape_convert(src, 'default-avatar', target_dir, 'png')
    inkscape_convert(src, 'logo', target_dir, 'png')
    inkscape_convert(src, 'icon', target_dir, 'png')
    inkscape_convert(src, 'icon-android-background', target_dir, 'png', id_only=True)
    inkscape_convert(src, 'icon-android-foreground', target_dir, 'png', id_only=True)
    inkscape_convert(src, 'icon-android-notification', target_dir, 'png')
    inkscape_convert(src, 'favicon', target_dir, 'png')
    inkscape_convert(src, 'favicon-32x32', target_dir, 'png')
    inkscape_convert(src, 'favicon-16x16', target_dir, 'png')
    inkscape_convert(src, 'apple-touch-icon', target_dir, 'png')
    inkscape_convert(src, 'social-card-default', target_dir, 'png')
    inkscape_convert(src, 'social-card-default-gradient', target_dir, 'png')
    inkscape_convert(src, 'safari-pinned-tab', target_dir, 'svg', id_only=True)
    inkscape_convert(src, 'Logotype', target_dir, 'svg', id_only=True)
    inkscape_convert(src, 'icon', target_dir, 'svg', id_only=True)
    inkscape_convert(src, 'logo', target_dir, 'svg', id_only=True)
    inkscape_convert(src, 'email_logo_default', target_dir, 'png')
    inkscape_convert(src, 'email_mark_dark', target_dir, 'png')
    inkscape_convert(src, 'email_mark_light', target_dir, 'png')
    compactify_svg.compactify(join(target_dir, 'safari-pinned-tab.svg'), join(target_dir, 'safari-pinned-tab.compact.svg'))
    compactify_svg.compactify(join(target_dir, 'Logotype.svg'), join(target_dir, 'Logotype.compact.svg'))
    compactify_svg.compactify(join(target_dir, 'icon.svg'), join(target_dir, 'icon.compact.svg'))
    compactify_svg.compactify(join(target_dir, 'logo.svg'), join(target_dir, 'logo.compact.svg'))

def show_files(target_dir):
    for filename in os.listdir(target_dir):
        subprocess.run(magick_prefix + ["identify", filename], cwd=target_dir)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('src_image', help="A branding image with the necessary ids to generate all the required images")
    parser.add_argument('target_dir', default=None, nargs='?', help="Where the generated images should be written (default: `dirname src_image`/generated)")
    args = parser.parse_args()
    logging.getLogger().setLevel(logging.INFO)
    if not exists(args.src_image):
        parser.error(f"Could not find source image {args.src_image}")
    if not args.target_dir:
        args.target_dir = join(dirname(args.src_image), "generated")
    if not os.path.exists(args.target_dir):
        os.makedirs(args.target_dir)
    export_images(args.src_image, args.target_dir)
    show_files(args.target_dir)

