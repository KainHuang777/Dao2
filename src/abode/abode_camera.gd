extends Camera2D
signal world_clicked(point: Vector2)
signal view_changed()

const MIN_ZOOM: float = 0.06
const MAX_ZOOM: float = 1.6
var target_zoom: float = 0.70
var target_position: Vector2 = Vector2(0, -40)
var home_position := Vector2(0, -40)
var home_zoom := 0.70
var reduced_motion: bool = false
var dragging: bool = false
var input_locked: bool = false
var dragged: bool = false
var press_origin: Vector2
var contacts: Dictionary = {}
var was_multitouch: bool = false
var zoom_anchor_active: bool = false
var zoom_anchor_world: Vector2
var zoom_anchor_screen: Vector2

func _ready() -> void:
	position = target_position
	zoom = Vector2.ONE * target_zoom

func _process(delta: float) -> void:
	var blend: float = 1.0 if reduced_motion else 1.0 - exp(-delta * 7.0)
	if absf(zoom.x - target_zoom) < 0.0005:
		zoom = Vector2.ONE * target_zoom
	else:
		zoom = Vector2.ONE * lerpf(zoom.x, target_zoom, blend)

	if zoom_anchor_active:
		target_position = zoom_anchor_world - (zoom_anchor_screen - get_viewport_rect().size * 0.5) / zoom.x
		position = target_position
		if absf(zoom.x - target_zoom) < 0.001:
			zoom_anchor_active = false
	else:
		if position.distance_squared_to(target_position) < 0.25:
			position = target_position
		else:
			position = position.lerp(target_position, blend)

func focus_home() -> void:
	zoom_anchor_active = false
	target_position = home_position
	target_zoom = home_zoom
	print("ABODE_CAMERA_HOME")
	view_changed.emit()

func focus_region() -> void:
	zoom_anchor_active = false
	target_position = Vector2(80, -390)
	target_zoom = 0.18
	print("ABODE_CAMERA_REGION")
	view_changed.emit()

func focus_cosmos() -> void:
	zoom_anchor_active = false
	target_position = Vector2(0, -100)
	target_zoom = 0.08
	print("ABODE_CAMERA_COSMOS")
	view_changed.emit()

func change_zoom(factor: float, anchor: Vector2 = Vector2(-1, -1)) -> void:
	target_zoom = clampf(target_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if anchor.x >= 0:
		zoom_anchor_world = position + (anchor - get_viewport_rect().size * 0.5) / zoom.x
		zoom_anchor_screen = anchor
		zoom_anchor_active = true
	else:
		zoom_anchor_active = false
	print("ABODE_CAMERA_ZOOM target=", snappedf(target_zoom, 0.001))
	view_changed.emit()

## The Web canvas forwards pointer events before Godot's GUI dispatch in some
## browsers. Handle world gestures here, then explicitly leave HUD controls
## alone so a building remains selectable with an ordinary mouse click.
func _input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouse and get_viewport().gui_get_hovered_control() != null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			change_zoom(1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			change_zoom(1.0 / 1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				dragged = false
				press_origin = event.position
				zoom_anchor_active = false
			elif dragging:
				dragging = false
				if not dragged:
					world_clicked.emit(position + (event.position - get_viewport_rect().size * 0.5) / zoom.x)
				else:
					print("ABODE_CAMERA_PAN position=", position.round())
	elif event is InputEventMouseMotion and dragging:
		if event.position.distance_to(press_origin) > 12.0:
			dragged = true
		if dragged:
			target_position -= event.relative / zoom.x
			target_position = target_position.clamp(Vector2(-2200, -2200), Vector2(2200, 1600))
			position = target_position
	elif event is InputEventScreenTouch:
		if event.pressed:
			if contacts.is_empty():
				was_multitouch = false
				press_origin = event.position
				dragged = false
			contacts[event.index] = event.position
			if contacts.size() > 1:
				was_multitouch = true
		else:
			if contacts.has(event.index) and contacts.size() == 1 and not dragged and not was_multitouch:
				world_clicked.emit(position + (event.position - get_viewport_rect().size * 0.5) / zoom.x)
			contacts.erase(event.index)
	elif event is InputEventScreenDrag and contacts.has(event.index):
		zoom_anchor_active = false
		if contacts.size() == 2:
			var pts: Array = contacts.values()
			var before: float = (pts[0] as Vector2).distance_to(pts[1])
			contacts[event.index] = event.position
			pts = contacts.values()
			var after: float = (pts[0] as Vector2).distance_to(pts[1])
			if before > 1:
				change_zoom(after / before, (pts[0] + pts[1]) * 0.5)
		else:
			contacts[event.index] = event.position
			if event.position.distance_to(press_origin) > 12:
				dragged = true
			if dragged:
				target_position -= event.relative / zoom.x
				target_position = target_position.clamp(Vector2(-2200, -2200), Vector2(2200, 1600))
				position = target_position
	elif event is InputEventMagnifyGesture:
		change_zoom(event.factor, event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_HOME: focus_home()
			KEY_MINUS, KEY_KP_SUBTRACT: change_zoom(0.8)
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD: change_zoom(1.25)
			KEY_M: focus_region()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		dragging = false
		contacts.clear()
