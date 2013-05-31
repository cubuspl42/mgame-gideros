#!/usr/bin/python
import os
import sys
import argparse
import posixpath
from lxml import etree as ET

script_name = 'dev_update'
folders = ['data', 'lib']
filename = 'mgame.gproj'

def readfile(filepath) :
	try:
		with open(filepath, 'r') as f:
			return f.read()
	except IOError: return ""

desc = script_name + """ updates mgame.gproj with files from 'data' and 'lib', recursively."""
parser = argparse.ArgumentParser(description=desc)
parser.add_argument('--dev-too', action='store_true',
					help="don't skip items starting with 'dev_'")
argv = sys.argv
if len(argv) < 2 :
	print "Reading arguments from " + script_name + "_args.txt..."
	argv = readfile(script_name + '_args.txt').split()
args = parser.parse_args(argv)

parser = ET.XMLParser(remove_blank_text=True)
tree = ET.parse(filename, parser)
root = tree.getroot()

for folderTag in root.findall('folder') :
	if folderTag.attrib['name'] in folders :
		root.remove(folderTag)

def walk(rootpath, tag) :
	for item in os.listdir(rootpath) :
		if item.startswith(".") or (item.startswith("dev_") and not args.dev_too) :
			continue
		path = posixpath.join(rootpath, item)
		print(path)
 	   	if os.path.isdir(path) :
 	   		folder = ET.SubElement(tag, 'folder', {'name': item })
 	   		walk(path, folder)
		else :
			file = ET.SubElement(tag, 'file', {'source': path, 'excludeFromExecution': '1'})

for folder in folders :
	tag = ET.SubElement(root, 'folder', {'name': folder})
	walk(folder, tag)
	
tree.write(filename, pretty_print=True)
