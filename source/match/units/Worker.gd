extends "res://source/match/units/Unit.gd"

var resource_a = 0
var resource_b = 0
var resources_max = null

@onready var _animation_player = find_child("AnimationPlayer")


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
