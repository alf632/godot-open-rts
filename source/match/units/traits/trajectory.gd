extends Node3D

@export var draw_trajectory := false
@export var max_points := 20
@export var marker_radius := 0.05

@onready var _ta = get_parent()
@onready var _unit = _ta.get_parent()
@onready var _turret = _unit.find_child("Geometry").find_child("turret", true, false)
@onready var _origin = _turret.find_child("ProjectileOrigin", true, false) if _turret != null else null
@onready var _match = find_parent("Match")
@onready var _terrain = _match.map.find_child("Terrain3D")

var _down = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var pos = null
var last_pos = null
var vel = null
var current_point = 0
var last_terrain_hit = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if draw_trajectory and _turret != null:
		if current_point >= max_points:
			pos = null
		
		if not pos:
			current_point = 0
			pos = _origin.global_position
			vel = -_origin.global_transform.basis.z * 15

		draw_point(pos, marker_radius, Color.WHITE_SMOKE, 1)
		vel += _down * _gravity * delta
		last_pos = pos
		pos += vel * delta
		current_point += 1
		if pos.y <= _terrain.storage.get_height(pos):
			last_terrain_hit = last_pos
			pos = null

func draw_point(pos: Vector3, radius = 0.05, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = sphere_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	sphere_mesh.radius = radius
	sphere_mesh.height = radius*2
	sphere_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms)

## 1 -> Lasts ONLY for current physics frame
## >1 -> Lasts X time duration.
## <1 -> Stays indefinitely
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
