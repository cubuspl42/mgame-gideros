#!/usr/bin/python
from os import listdir, error, makedirs
from os.path import isdir, join, abspath, exists
from lxml import etree
import subprocess
from subprocess import call
import hashlib
import argparse
import sys
import time

##########################################################################################
# globals

gTag = "{http://www.w3.org/2000/svg}g"
layerNameAttribute = "{http://www.inkscape.org/namespaces/inkscape}label"
directories = [ dir for dir in listdir(".") if isdir(dir) ]
exportarg = { 'png': "--export-png", 'svg': "--export-plain-svg" }
spriterscale = 4

##########################################################################################
# helpers

def filemd5(filepath):
    with open(filepath, 'rb') as f:
        m = hashlib.md5()
        while True:
            data = f.read(8192)
            if not data:
                break
            m.update(data)
        return m.hexdigest()
        
def readfile(filepath) :
	try:
		with open(filepath, 'r') as f:
			return f.read()
	except IOError: return ""
	
def writefile(filepath, content) :
	with open(filepath, 'w') as f:
		return f.write(content)

def trymakedirs(*args) :
	try: makedirs(*args)
	except error: print "directory not created"

def absjoin(*args) :
	return abspath(join(*args))
	
##########################################################################################
# functions

def get_base_layers(dir) :
	print "\n\n--> get_base_layers\n"
	layers = []
	parser = etree.XMLParser(remove_blank_text=True)
	dev_base = absjoin(dir, "dev_base.svg")
	tree = etree.parse(dev_base, parser)
	root = tree.getroot()
	
	for g in root.findall(gTag) :
		layerName = g.attrib[layerNameAttribute]
		layers.append({'id': g.attrib["id"], 'name': layerName})

	for layer in layers :
		print "--> Getting info for layer " + layer['name']
		for z in ['x', 'y', 'width', 'height'] :
			params = ["inkscape", "-z", "--query-id=" + layer['id'], "--query-" + z, dev_base]
			print "-> Calling inkscape with:\n", params
			print "-> Inkscape output:"
			process = subprocess.Popen(params, stdout=subprocess.PIPE)
			out, err = process.communicate()
			print "-> Out:"
			print out
			print "-> Err:"
			print err
			layer[z] = float(out)
	
	return layers

def export_base(dir, imgsubfolder, format, layers, scale=1, postfix='') :
	print "\n\n--> export_base\n"
	dev_base = absjoin(dir, "dev_base.svg")
	imgpath = join(dir, imgsubfolder)
	
	print "--> Getting height of image"
	z = 'height'
	params = ["inkscape", "-z", "--query-" + z, dev_base]
	print "-> Calling inkscape with:\n", params
	print "-> Inkscape output:"
	process = subprocess.Popen(params, stdout=subprocess.PIPE)
	out, err = process.communicate()
	print "-> Out:"
	print out
	print "-> Err:"
	print err
	imgheight = float(out)
	
	for layer in layers :
		id = layer['id']
		name = layer['name']
		x0 = layer['x'] - 2
		y0 = imgheight - (layer['y'] - 2)
		x1 = x0 + layer['width'] + 3
		y1 = imgheight - ( y0 + layer['height'] + 3)
		
		if imgsubfolder == 'img' and name.startswith("dev_") :
			continue
		layersubfolder = join(imgpath, name)
		imgfilename = absjoin(layersubfolder, "img" + postfix + "." + format)
		print "\n--> Layer: '%s', format = '%s', posfix = '%s', scale = '%s'" % (name, format, postfix, scale)
		print "-> Creating directory " + layersubfolder + "... "
		trymakedirs(layersubfolder)
		
		params = ["inkscape", "--without-gui", exportarg[format] + "=" + imgfilename, "--export-dpi=" + str(scale * 90), 
		"--export-id=" + id, "--export-id-only", "--export-area=%d:%d:%d:%d" % (int(x0), int(y0), int(x1), int(y1)), dev_base]
		print "-> Calling inkscape with:\n", params
		print "-> Inkscape output:"
		call(params)
	pass
	
def generate_scml(dir, layers) :
	print "\n\n--> generate_scml\n"
	anim = absjoin(dir, "anim.scml")
	if exists(anim) :
		print "anim.scml exists, skipping"
		return
	root = etree.Element('spriter_data', {'scml_version':'1.0', 'generator':'dev_gen', 'generator_version':'v1'})
	tree = etree.ElementTree(root)
	entity = etree.SubElement(root, 'entity', {'id': '0', 'name': dir })
	animation = etree.SubElement(entity, 'animation', {'id':'0', 'name':'Idle','length':str(1000)})
	mainline = etree.SubElement(animation, 'mainline')
	mainkey = etree.SubElement(mainline, 'key', {'id':'0'})
	
	for i, layer in enumerate(layers) :
		si = str(i)
		name = layer['name']
		x = layer['x'] * spriterscale
		y = layer['y'] * -spriterscale
		
		timeline = etree.SubElement(animation, 'timeline', {'id': si, 'name': name})
		key = etree.SubElement(timeline, 'key', {'id':'0'})
		object = etree.SubElement(key, 'object', {'folder':si, 'file':'0', 'x':str(x), 'y':str(y)})
		
		foldername = '/dev_img/' + name
		folder = etree.SubElement(root, 'folder', {'id': si, 'name': foldername })
		file = etree.SubElement(folder, 'file', {'id': '0', 'name': foldername + '/img.png' })
		
		object_ref = etree.SubElement(mainkey, 'object_ref', {'id':si, 'timeline':si, 'key':'0', 'z_index':si})
	
	def srt(a, b) :
		if a.tag == 'folder' :
			if b.tag == 'folder' :
				return cmp(int(a.attrib["id"]), int(b.attrib["id"]))
			return -1
		if a.tag == 'entity' and b.tag == 'folder' :
				return 1
		return 0
	root[:] = sorted(root, srt)
	
	s = etree.tostring(root, pretty_print=True)
	print s
	tree.write(anim, pretty_print=True)

##########################################################################################
# main

desc = '''dev_gen generates png images and SCML file from dev_base.svg.
It will never overwrite scml, but it will override pngs if dev_base.md5 doesn't match.'''
parser = argparse.ArgumentParser(description=desc)
parser.add_argument('--force', action='store_true',
					help="generate pngs even if svg_base.md5 hasn't changed")
parser.add_argument('--dev-only', action='store_true',
					help="generate images only in 'dev_img', not in 'img'")
argv = sys.argv[1:]
if len(argv) < 1 :
	print "Reading arguments from dev_gen_args.txt..."
	argv = readfile('dev_gen_args.txt').split()
args = parser.parse_args(argv)

scalessrc = readfile(join('.','dev_gen_scales.txt'))
print "*** Scales: ", scalessrc, " ***"
scales = eval(scalessrc)

if args.dev_only :
	print "*** Generating ONLY dev_img ***"
	
if args.force :
	print "*** Will ignore md5 check result ***"
	
time.sleep(2)
	
for dir in directories :
	print "\n---> Entity directory: " + dir
	dev_base = absjoin(dir, "dev_base.svg")
	dev_base_md5 = absjoin(dir, "dev_base.md5")
	oldmd5 = readfile(dev_base_md5)
	newmd5 = filemd5(dev_base)
	
	print "Old md5 = '%s', new md5 = '%s'" % (oldmd5, newmd5)
	if oldmd5 == newmd5 :
		print "md5 didn't change"
		if not args.force : continue
	
	layers = get_base_layers(dir)
	if not args.dev_only :
		for postfix, scale in scales.iteritems() : 
			export_base(dir, "img", "png", layers, scale, postfix)
	export_base(dir, "dev_img", "png", layers, scale = spriterscale)
	generate_scml(dir, layers)
	
	writefile(dev_base_md5, newmd5)
	