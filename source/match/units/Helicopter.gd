extends "res://source/match/units/Unit.gd"

const ROTOR_SPEED = 800.0  # degrees/s

const WaitingForTargets = preload("res://source/match/units/actions/WaitingForTargets.gd")

var default_action = WaitingForTargets

func _ready():
	await super()
	find_child("Movement").domain = Constants.Match.Navigation.Domain.AIR


func _physics_process(delta):
	find_child("Rotor").rotation_degrees.y += ROTOR_SPEED * delta
