#!/usr/bin/env python

import xml.etree.ElementTree as etree
import logging
import sys
import re

NS = {
  'svg': '{http://www.w3.org/2000/svg}',
  'xlink': '{http://www.w3.org/1999/xlink}',
}

remove_font_styles = {'font-weight', 'font-size', 'font-family', '-inkscape-font-specification', 'line-height'}

style_url_re = re.compile('url[(]#([^)]*)[)]')

def register_all_namespaces(filename):
    namespaces = dict([node for _, node in etree.iterparse(filename, events=['start-ns'])])
    for ns in namespaces:
        if ns == '':
            continue
        etree.register_namespace(ns, namespaces[ns])
    # do this last so it is used as default
    if '' in namespaces:
        etree.register_namespace('', namespaces[''])

def compactify(input_filename, output_filename):
    register_all_namespaces(input_filename)
    svg_file = etree.parse(input_filename)
    logging.info("Parsed %s", svg_file)
    root = svg_file.getroot()
    used_ids = []
    for object_with_style in root.findall(f'.//{NS["svg"]}*[@style]'):
        object_style = object_with_style.attrib.get('style')
        used_ids.extend(style_url_re.findall(object_style))
    for gradient in root.findall(f'.//{NS["svg"]}linearGradient'):
        gradient_id = gradient.attrib['id']
        if gradient_id in used_ids:
            href = gradient.attrib.get(f'{NS["xlink"]}href')
            if href and href.startswith('#'):
                href_id = href[1:]
                if href_id not in used_ids:
                    used_ids.append(href_id)
    for gradient_parent in root.findall(f'.//{NS["svg"]}linearGradient/..'):
        removals = []
        for child in gradient_parent:
            if child.tag == f'{NS["svg"]}linearGradient':
                child_id = child.attrib['id']
                if child_id in used_ids:
                    print(f"keeping {child.tag} {child_id}; in use")
                else:
                    print(f"removing {child.tag} {child_id}")
                    removals.append(child)
        for child in removals:
            gradient_parent.remove(child)
    for defs_parent in root.findall(f'.//{NS["svg"]}defs/..'):
        removals = []
        for child in defs_parent:
            if child.tag == f'{NS["svg"]}defs':
                if not len(list(child)):
                    print(f"removing {child.tag} {child.attrib['id']} - no children")
                    removals.append(child)
        for child in removals:
            defs_parent.remove(child)
    for path in root.findall(f'.//{NS["svg"]}path'):
        path_style = path.attrib.get('style')
        if path_style:
            path_styles = path_style.split(';')
            path_styles = [style for style in path_styles if not style[:style.find(':')] in remove_font_styles]
            new_path_style = ';'.join(path_styles)
            if new_path_style != path_style:
                print(f"removing font styles from path {path.attrib['id']}")
                path.attrib['style'] = new_path_style
    with open(output_filename, 'wb') as out_file:
        out_file.write(etree.tostring(root))
    # svg_file.write(output_filename, encoding = "utf-8", xml_declaration = True)
    logging.info("Wrote compactified SVG to %s", output_filename)

if __name__ == '__main__':
    for arg in sys.argv[1:]:
        if not arg.endswith('.svg'):
            logging.error("Unknown argument %s", arg)
            continue
        compactify(arg, arg.replace('.svg', '.compact.svg'))
