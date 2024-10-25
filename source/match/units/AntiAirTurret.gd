extends "res://source/match/units/Structure.gd"

const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

var default_action = WaitingForTargets

func _ready():
	await super()
	find_child("Geometry").visible = visible
	visibility_changed.connect(func(): find_child("Geometry").visible = visible)
	if not is_constructed():
		await constructed
