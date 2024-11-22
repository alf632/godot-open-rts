extends SubViewport

const GroundObstacleMarker = preload("res://source/match/handlers/ground_obstacle_marker.gd")

var obstacles = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func register_obstacle(obs :GroundObstacleMarker) -> void:
	add_child(obs)
	obs.queue_redraw()

func query_position(position :Vector2) -> float:
	var pixel = get_texture().get_image().get_pixelv(position)
	return pixel.r
