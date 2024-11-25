extends "res://source/match/units/Unit.gd"

var resource_a = 0
var resource_b = 0
var resources_max = null

@onready var _animation_player = find_child("AnimationPlayer")
@onready var _movement = $Movement


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
		var altDir = _movement._calculate_hold_altitude_dir()
		var stablelizing = _movement._calculate_stabilizing_torque()
		state.apply_torque(stablelizing[0] * _movement.angularForce)
		if stablelizing[1]:
			dir = _movement._nav.get_velocity()
			state.apply_torque(_movement._calculate_dir_torque(dir) * _movement.angularForce)
			dir = lerp(dir, altDir.normalized(), altDir.length())
			state.apply_central_force(dir * _movement.linearForce)
		#else:
		#	state.apply_central_force(altDir.normalized() * _movement.linearForce)
