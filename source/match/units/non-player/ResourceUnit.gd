extends Area3D

const ResourceDecayAnimation = preload("res://source/match/utils/ResourceDecayAnimation.tscn")

@export var radius = 5
var global_position_yless:
	get:
		return global_position * Vector3(1, 0, 1)
var in_base

func _enter_tree():
	tree_exiting.connect(_animate_decay)


func _animate_decay():
	var decay_animation = ResourceDecayAnimation.instantiate()
	decay_animation.global_transform = global_transform
	get_parent().add_child.call_deferred(decay_animation)

func collect_resource(unit):
	if 	"resource_a" in self and self.resource_a > 0:
		self.resource_a -=1
		unit.resource_a +=1
	elif "resource_b" in self and self.resource_b > 0:
		self.resource_b -=1
		unit.resource_b +=1
	else:
		queue_free()
