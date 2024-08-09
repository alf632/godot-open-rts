@tool
extends Node

@onready var terrainMesh = $"../".find_child("Terrain") # MeshInstance used for Rendering and NavMesh
@onready var colShape := $CollisionShape3D #the shape is used as child of a Match to detect mouse inputs

@onready var navigation = $"../../".find_child("Navigation")

@onready var shader := preload("res://source/match/maps/Heightmap/terrain-mat.gdshader")

@export var mesh_scale := 1.0

var heightmap : Image
var gradient := preload("res://source/match/maps/Heightmap/gradient.tres")

var resolution : Vector2
var cellSize : float = 1.0 # verts/m
var verts : PackedVector3Array
var indices : PackedInt32Array

func _ready():
	readRawHeightmap()
	setupHeightmap()
	genVerts()
	genIndex()
	updateTerrainTex()
	updateTerrainMesh(genMesh())
	updateTerrainShape()
	#updateUnits() - handled by unit_spawned signal
	if not Engine.is_editor_hint():
		var terrain = find_parent("Match").get_node("Terrain")
		remove_child(colShape)
		terrain.find_child("CollisionShape3D").replace_by(colShape)
		setupNavigation()
	#terrainMesh.mesh = colShape.shape.get_debug_mesh()
	MatchSignals.connect("unit_spawned", updateUnit)


func _process(delta):
	pass

func setupHeightmap():
	var shaderMat := ShaderMaterial.new()
	shaderMat.shader = shader
	var gradTex = GradientTexture1D.new()
	gradTex.gradient = gradient
	shaderMat.set_shader_parameter("_a", gradTex)
	terrainMesh.set_surface_override_material(0, shaderMat)
	heightmap.convert(Image.FORMAT_RF)
	#heightmap.resize(heightmap.get_width()*heightmap_scale, heightmap.get_height()*heightmap_scale)
	resolution = heightmap.get_size()
	var meshSize = heightmap.get_size()*mesh_scale
	$"../".size=meshSize
	#terrain.mesh.size = meshSize
	#terrain.mesh.center_offset = Vector3(meshSize.x, 0.0, meshSize.y) / 2.0
	#terrainMesh.mesh.set("subdivide_width", heightmap.get_size().x)
	#terrainMesh.mesh.set("subdivide_depth", heightmap.get_size().y)
	#terrainMesh.get_surface_override_material(0).set_shader_parameter("src_size", heightmap.get_size())

func setupNavigation():
	navigation.get_node("Terrain/NavigationRegion3D").navigation_mesh.cell_size = cellSize
	#navigation.get_node("Air/NavigationRegion3D").navigation_mesh.cell_size = cellSize

func updateTerrainMesh(mesh:Mesh):
	terrainMesh.mesh = mesh
	#var mdt = MeshDataTool.new()
	#mdt.create_from_surface(terrainMesh.mesh, 0)
	#var heights = heightmap.get_data().to_float32_array()
	#var width = int($"../".size.x)
	#for i in range(0, len(heights)):
	#	var vert = Vector3(i%width, heights[i], i/width)
	#	mdt.set_vertex(i, vert)
	#terrainMesh.mesh.surface_remove(0)
	#mdt.commit_to_surface(terrainMesh.mesh)

func updateTerrainTex():
	var tex = ImageTexture.create_from_image(heightmap)
	terrainMesh.get_surface_override_material(0).set_shader_parameter("heightmap", tex)

func updateTerrainShape():
	var data = heightmap.get_data()
	colShape.shape.map_width = heightmap.get_width()
	colShape.shape.map_depth = heightmap.get_height()
	colShape.shape.map_data = data.to_float32_array()

func updateNavigation():
	navigation.rebake(get_parent())

func updateUnits():
	for unit in get_tree().get_nodes_in_group("units"):
		updateUnit(unit)

func updateUnit(unit):
	var pos = Vector3i(floor(unit.global_transform.origin))
	unit.global_transform.origin.y = getHeight(Vector2i(pos.x,pos.z))

func readRawHeightmap():
	var file = FileAccess.open("res://source/match/maps/Heightmap/heightmap.raw", FileAccess.READ)
	if file.get_position() >= file.get_length():
		file.seek(0)
	var sizeX := file.get_16()
	var sizeY := file.get_16()
	var framelen := file.get_32()
	var byteFrame: PackedByteArray = file.get_buffer(framelen)
	heightmap = Image.create_from_data(sizeX,sizeY, false, Image.FORMAT_RF, byteFrame)

func getHeight(vec : Vector2i):
	return heightmap.get_pixelv(Vector2i(vec)).r

func genMesh():
	var mesh := ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
	
func genVerts():
	verts = PackedVector3Array()
	var heights = heightmap.get_data().to_float32_array()
	verts.resize(len(heights))
	for i in range(0, len(heights)):
		verts[i] = Vector3(i%int(resolution.x),heights[i],i/int(resolution.x))
	#for z in range(0, resolution.y):
	#	for x in range(0, resolution.x):
	#		var vert = Vector3(x,heights[z*x+x],z)
	#		verts.append(vert)

func genIndex():
	indices = PackedInt32Array()
	for row in range(0, resolution.y-1):
			for col in range(0,resolution.x-1):
					var v_idx = row*(resolution.x)+col

					indices.push_back(v_idx)
					indices.push_back(v_idx + 1)
					indices.push_back(v_idx + resolution.x)

					indices.push_back(v_idx + resolution.x)
					indices.push_back(v_idx + 1)
					indices.push_back(v_idx + resolution.x + 1)
