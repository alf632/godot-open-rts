extends "res://source/match/units/Structure.gd"

func _ready() -> void:
	var base = find_parent("Match").find_child("Handlers").find_child("BaseHandler").new_base(self)
	base.color = self.player.color
	base.register_structure(self)
	super()
