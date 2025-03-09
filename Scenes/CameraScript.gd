extends Camera2D

var target

var target_return_enabled = true
var target_return_rate = 0.02
var min_zoom = 0.5
var max_zoom = 2
var zoom_speed = 0.05
var zoom_sens = 10

var events = {}
var last_drag_dist = 0

func _process(delta: float) -> void:
	if target and target_return_enabled and events.size() == 0:
		position = lerp(position, get_node(target).position, target_return_rate)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index]
