#!/usr/bin/python
import os
import sys
import argparse
from lxml import etree as ET

script_name = 'dev_update'
data_folder = 'data'
filename = 'mgame.gproj'

def readfile(filepath) :
	try:
		with open(filepath, 'r') as f:
			return f.read()
	except IOError: return ""

desc = script_name + """ updates mgame.gproj with files from 'data', recursively."""
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

for folder in root.findall('folder') :
	if folder.attrib['name'] == data_folder :
		root.remove(folder)
		
data = ET.SubElement(root, 'folder', {'name': data_folder})
			
def walk(root, tag) :
	for item in os.listdir(root) :
		if item.startswith(".") or (item.startswith("dev_") and not args.dev_too) :
			continue
		path = os.path.join(root, item)
		print(path)
 	   	if os.path.isdir(path) :
 	   		folder = ET.SubElement(tag, 'folder', {'name': item })
 	   		walk(path, folder)
		else :
			file = ET.SubElement(tag, 'file', {'source': path, 'excludeFromExecution': '1'})
			
walk(data_folder, data)
tree.write(filename, pretty_print=True)
