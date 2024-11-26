extends "res://source/match/units/Unit.gd"

const kind = "Tank"

const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

var default_action = WaitingForTargets
