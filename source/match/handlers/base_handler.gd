extends Node3D

const CommandCenter = preload("res://source/match/units/CommandCenter.gd")

const Base = preload("res://source/match/Base.tscn")

const BaseStructureOverlay = preload("res://source/match/base_structure_overlay.gd")

@onready var _match = find_parent("Match")
@onready var _players = _match.find_child("Players")
@onready var _units = _match.find_child("Units")
@onready var _bases = find_child("Bases")
@onready var _vp = find_child("Territories")
@onready var _territories_texture = find_child("TerritoriesTexture")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await _match.ready  # make sure Match is ready as it may change map on setup
	if not _match.is_initialized:
		set_process(false)
		await MatchSignals.match_started
		set_process(true)
	_vp.size = (
		_match.find_child("Map").size
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#called by CommandCenter on spawn
func new_base(command_center :CommandCenter):
	var newBase = Base.instantiate()
	newBase.command_center = command_center
	command_center.player.bases.append(newBase)
	_bases.add_child(newBase)
	return newBase

func add_overlay(overlay :BaseStructureOverlay):
	print("adding overlay at ",overlay.position)
	_vp.add_child(overlay)
	overlay.queue_redraw()

func refresh_overlays():
	for overlay in _vp.get_children():
		overlay.queue_redraw()

func get_base_at(pos :Vector2):
	var color = _territories_texture.texture.get_image().get_pixelv(pos)
	for base in _bases.get_children():
		if base.color == color:
			return base
	return null
