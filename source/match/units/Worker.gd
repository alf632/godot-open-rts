extends "res://source/match/units/Unit.gd"

var resource_a = 0
var resource_b = 0
var resources_max = null

@onready var _animation_player = find_child("AnimationPlayer")
@onready var _movement = $Movement
@export var damping_factor := 1.0
@export var error_factor := 1.0
@export var stablizing_threshold := 20.0
@export var y_weight := 1.5

func is_full():
	assert(resource_a + resource_b <= resources_max, "worker capacity was exceeded somehow")
	return resource_a + resource_b == resources_max

func is_loaded():
	return resource_a > 0 or resource_b > 0

func play_collect_animation():
	if not _animation_player.is_playing():
		_animation_player.play("work", -1, 3)

func reset_animation():
	if not _animation_player.is_playing():
		AnimationPlayer.new().play()
		_animation_player.stop()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var dir := Vector3()
	if _movement.piloted:
		dir = _movement._direct.get_velocity()
		state.apply_central_force(dir * movement_speed)
		return
	else:
		#clamp_angles(state)
		#var altDir = _movement._calculate_hold_altitude_dir()
		#var stablelizing = _movement._calculate_stabilizing_torque()
		#state.apply_torque(stablelizing[0] * _movement.angularForce)
		#if stablelizing[1]:
		#	dir = _movement._nav.get_velocity()
		#	state.apply_torque(_movement._calculate_dir_torque(dir) * _movement.angularForce)
		#	dir = lerp(dir, altDir.normalized(), altDir.length())
		#	state.apply_central_force(dir * _movement.linearForce)
		#else:
		#	state.apply_central_force(Vector3.UP * 10)
		
		var altDir = _movement._calculate_hold_altitude_dir()
		var navDir = _movement._nav.get_velocity()
		dir = lerp(navDir, altDir.normalized(), altDir.length())
		if navDir == Vector3():
			navDir = -state.transform.basis.z
		
		_torque_towards_dir(navDir, state)
		
		state.apply_central_force(dir * _movement.linearForce)

func _torque_towards_dir(dir: Vector3, state: PhysicsDirectBodyState3D) -> void:
	# Zielrotation (als Quaternion oder Eulerwinkel)
	var dir2d = dir * Vector3(1,0,1)
	var target_rotation = look_there(dir2d.normalized())
	# Aktuelle Rotation als Quaternion
	var current_rotation = state.transform.basis.get_rotation_quaternion()
	# Differenz zwischen Ziel- und aktueller Rotation (als Quaternion)
	var rotation_error = target_rotation * current_rotation.inverse()
	if rotation_error.get_angle() < stablizing_threshold:
		return
	# Winkelgeschwindigkeit als Vektor
	var angular_velocity = state.angular_velocity
	# Drehmoment berechnen (Proportional zur Winkelgeschwindigkeit und dem Rotationsfehler)
	var torque = -angular_velocity * damping_factor - rotation_error.get_euler() * error_factor
	# Drehmoment anwenden
	state.apply_torque(torque * Vector3(1,y_weight,1))

func clamp_angles(state: PhysicsDirectBodyState3D):
	var euler = state.transform.basis.get_euler()
	var clamped = false
	if euler.x > PI/4:
		euler.x = PI/4
		clamped = true
	elif euler.x < -PI/4:
		euler.x = -PI/4
		clamped = true
	if euler.z > PI/4:
		euler.z = PI/4
		clamped = true
	elif euler.z < -PI/4:
		euler.z = -PI/4
		clamped = true
	if clamped:
		state.transform.basis.from_euler(euler)

func look_there(direction: Vector3, up: Vector3 = Vector3.UP) -> Quaternion:
	# Berechne den rechten Vektor (rechtshändiges Koordinatensystem)
	var right = direction.cross(up).normalized()
	# Berechne den neuen "oben"-Vektor
	var new_up = right.cross(direction).normalized()
	# Erstelle eine Rotationsmatrix aus den Basisvektoren
	var rotation_matrix = Basis(-right, new_up, -direction.normalized())
	# Konvertiere die Rotationsmatrix in eine Quaternion
	var rotation = rotation_matrix.get_rotation_quaternion()
	return rotation
