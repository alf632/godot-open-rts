extends Node3D


const Structure = preload("res://source/match/units/Structure.gd")
const Order = preload("res://source/match/units/orders/Order.gd")
const Orders = {
	"MoveToPosition" = preload("res://source/match/units/orders/MoveToPosition.gd"),
	"MoveToUnit" = preload("res://source/match/units/orders/MoveToUnit.gd"),
	"FollowUnit" = preload("res://source/match/units/orders/FollowUnit.gd"),
	"Construct" = preload("res://source/match/units/orders/Construct.gd"),
	"CollectResource" = preload("res://source/match/units/orders/CollectResource.gd"),
}

const Actions = {
	"Moving" = preload("res://source/match/units/actions/Moving.gd"),
	"MovingToUnit" = preload("res://source/match/units/actions/MovingToUnit.gd"),
	"Following" = preload("res://source/match/units/actions/Following.gd"),
	"CollectingResourcesSequentially" = preload(
		"res://source/match/units/actions/CollectingResourcesSequentially.gd"
	),
	"AutoAttacking" = preload("res://source/match/units/actions/AutoAttacking.gd"),
	"Constructing" = preload("res://source/match/units/actions/Constructing.gd"),
}


@onready var _unit = get_parent()

var current_order
var current_action
var order_queue = []

var _action_locked = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if not multiplayer.is_server():
	#	set_process(false)
	
	set_process(false)
	if _unit is Structure and not _unit.is_constructed():
		await _unit.constructed
	set_process(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_order and current_action:
		# nothing to do
		return
	
	if not current_order:
		if len(order_queue) > 0:
			current_order=order_queue.pop_front()
	
	if not multiplayer.is_server():
		return
	
	if not current_action:
		var next_action
		if current_order:
			next_action = current_order.get_action(self)
		elif "default_action" in _unit:
			next_action = _unit.default_action
		
		if next_action:
			set_action(next_action)
		
		
	

func set_order(order):
	if multiplayer.is_server():
		_do_set_order.rpc(order.to_string())
	else:
		request_set_order.rpc_id(1, order.to_string())

@rpc("any_peer", "reliable", "call_remote")
func request_set_order(order_string):
	_do_set_order.rpc(order_string)

@rpc("authority", "reliable", "call_local")
func _do_set_order(order_string):
	var ctx := Order.OrderContext.new()
	ctx.unit = _unit
	var orderClass = Orders[order_string.split(";")[0]]
	var newOrder = orderClass.new_from_string(order_string, ctx)
	if newOrder.to_be_queued:
		order_queue.append(newOrder)
	else:
		order_queue = []
		current_order = newOrder
		if multiplayer.is_server():
			set_action(current_order.get_action(self))


func set_action(action):
	if multiplayer.is_server():
		_do_set_action.rpc(action.to_string())
	else:
		request_set_action.rpc_id(1, action.to_string())

@rpc("any_peer", "reliable", "call_remote")
func request_set_action(action_string):
	_do_set_action.rpc(action_string)

@rpc("authority", "reliable", "call_local")
func _do_set_action(action_string):
	var action_node = Actions[action_string.split(";")[0]].new_from_string(action_string)
	
	if not is_inside_tree() or _action_locked:
		if action_node != null:
			action_node.queue_free()
		return
	_action_locked = true
	_teardown_current_action()
	current_action = action_node
	if current_action != null and multiplayer.is_server():
		add_child(action_node)
	_action_locked = false
	#action_changed.emit(action)

func _teardown_current_action():
	if current_action != null and current_action.is_inside_tree():
		current_action.queue_free()
		remove_child(current_action)  # triggers _on_action_node_tree_exited immediately
