from os import listdir
from os.path import isdir, join
from lxml import etree
from subprocess import call

gTag = "{http://www.w3.org/2000/svg}g"
layerNameAttribute = "{http://www.inkscape.org/namespaces/inkscape}label"
directories = [ dir for dir in listdir(".") if isdir(join(".", dir)) ]
exportarg = { 'png': "-e", 'svg': "-l" }

def export_base(dir, imgsubfolder, format, layers, postfix='', scale=1) :
	svg_base = join(dir, "svg_base.svg")
	imgpath = join(dir, imgsubfolder)
	for layer in layers :
		id = layer['id']
		name = layer['name']
		imgfilename = join(dir, imgsubfolder, name, "img" + postfix + "." + format)
		params = ["inkscape", "-z", exportarg[format] + "=" + imgfilename, "-i=" + id, svg_base]
		print params
		#call(params)
	pass
	
def generate_scml(dir, layers) :
	pass

for dir in directories :
	parser = etree.XMLParser(remove_blank_text=True)
	tree = etree.parse(join(dir, "dev_base.svg"), parser)
	root = tree.getroot()
	layers = []
	for g in root.findall(gTag) :
		layerName = g.attrib[layerNameAttribute]
		if not layerName.startswith("dev_") :
			layers.append({'id': g.attrib["id"], 'name': layerName})
			
	export_base("ninja", "img", "png", layers, postfix="@2x", scale=2)
	
	
	