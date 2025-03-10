extends Camera2D

@onready var target = "../CamTarget"

var target_return_enabled = false
const TARGET_RETURN_RATE = 0.02
const MIN_ZOOM = 0.7
const MAX_ZOOM = 2
const ZOOM_SPEED = 0.05
const ZOOM_SENS = 10
const CAM_MIN_POS = Vector2(-100, 0)
const CAM_MAX_POS = Vector2(500, 300)

var _target_zoom = 1.2
var events = {}
var last_drag_dist = 0

func _process(delta: float) -> void:
	if target and target_return_enabled and events.size() == 0:
		position = lerp(position, get_node(target).position, TARGET_RETURN_RATE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = events
		else:
			events.erase(event.index)
	elif event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() == 1:
			var new_pos = position + event.relative * zoom.x
			clamp(new_pos, MIN_ZOOM, MAX_ZOOM)
			position = new_pos
		elif events.size() == 2:
			var drag_distance = events[0].position.distance_to(events[1].position)
			if abs(drag_distance - last_drag_dist) > ZOOM_SENS:
				var new_zoom = (1 + ZOOM_SPEED) if drag_distance < last_drag_dist else (1 - ZOOM_SPEED)
				new_zoom = clamp(zoom.x * new_zoom, MIN_ZOOM, MAX_ZOOM)
				zoom = Vector2.ONE * new_zoom
				last_drag_dist = drag_distance
	elif event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			var new_pos = position - event.relative / zoom
			new_pos.x = clamp(new_pos.x, CAM_MIN_POS.x, CAM_MAX_POS.x)
			new_pos.y = clamp(new_pos.y, CAM_MIN_POS.y, CAM_MAX_POS.y)
			position = new_pos
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var new_zoom = 1 + ZOOM_SPEED
				new_zoom = clamp(zoom.x * new_zoom, MIN_ZOOM, MAX_ZOOM)
				zoom = Vector2.ONE * new_zoom
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var new_zoom = 1 - ZOOM_SPEED
				new_zoom = clamp(zoom.x * new_zoom, MIN_ZOOM, MAX_ZOOM)
				zoom = Vector2.ONE * new_zoom
