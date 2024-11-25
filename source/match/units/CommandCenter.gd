extends "res://source/match/units/Structure.gd"

@onready var animation :AnimationPlayer = find_child("AnimationPlayer")

var timer := 0.0

func _ready() -> void:
	var base = find_parent("Match").find_child("Handlers").find_child("BaseHandler").new_base(self)
	base.color = self.player.color
	base.register_structure(self)
	super()

func _process(delta: float) -> void:
	timer += delta
	if not timer >= 5.0:
		return
	timer = 0
	
	if not animation.is_playing():
		animation.play("idle")

func unload_resources(unit):
	player.resource_a += unit.resource_a
	player.resource_b += unit.resource_b
	unit.resource_a = 0
	unit.resource_b = 0
	return true
