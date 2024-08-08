extends HBoxContainer

signal selected(id)
signal name_changed(name)

var id: int

var player_id:
	set(val):
		player_id = val
		_check_if_editable()

var player_name = "":
	set(val):
		$Name.text = val
		if val:
			$Select.hide()
			$Name.show()
		else:
			$Select.show()
			$Name.hide()
	get:
		return $Name.text

func _check_if_editable():
	if player_id == multiplayer.get_unique_id():
		$Name.editable = true
	else:
		$Name.editable = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_select_pressed():
	selected.emit(id)


func _on_name_text_submitted(new_name):
	name_changed.emit(new_name)
