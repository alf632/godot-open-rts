extends "res://source/match/units/Unit.gd"

func _ready() -> void:
	super()
	$Movement.domain = Constants.Match.Navigation.Domain.AIR
