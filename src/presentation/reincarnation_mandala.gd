extends TextureRect
## Shared formal host; preserves the exhausted-life lamp and container sizing.
var elapsed := 0.0
var reduced_motion := false
var ceremonial := false
var _effect: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_effect = preload("res://src/presentation/reincarnation_fx/layered_effect.gd").new()
	add_child(_effect)
	_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visibility_changed.connect(_sync_processing)
	_sync_processing()
	_update_effect()

func _sync_processing() -> void:
	set_process(is_visible_in_tree())

func _process(delta: float) -> void:
	if not reduced_motion:
		elapsed = fmod(elapsed + minf(delta, 0.1), 1200.0)
	_update_effect()

func _update_effect() -> void:
	if _effect == null: return
	var spent := texture != null and texture.resource_path.ends_with("life_lamp_spent.png")
	self_modulate.a = 1.0 if spent else 0.0
	_effect.visible = not spent
	_effect.clock = elapsed
	_effect.reduced = reduced_motion
	_effect.ceremonial = ceremonial
	_effect.paper = not ceremonial
	_effect.apply_pose()