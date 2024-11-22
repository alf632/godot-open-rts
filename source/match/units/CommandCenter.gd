extends "res://source/match/units/Structure.gd"

func _ready() -> void:
	var base = find_parent("Match").find_child("Handlers").find_child("BaseHandler").new_base(self)
	base.color = self.player.color
	base.register_structure(self)
	super()

func unload_resources(unit):
	player.resource_a += unit.resource_a
	player.resource_b += unit.resource_b
	unit.resource_a = 0
	unit.resource_b = 0
	return true
