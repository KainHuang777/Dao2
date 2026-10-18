extends Control
const Effect = preload("res://effect.gd")
var effect: Control
var status: Label
var background: ColorRect
var paper := false
var controls := {}
var body: BoxContainer
var toolbar: GridContainer
var title: Label

func _ready() -> void:
	if OS.has_feature("web"):
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
		_sync_web_css_size()
		get_window().size_changed.connect(_on_web_resize)
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/runtime/Dao2Sans-VF.ttf")
	theme.default_font_size = 18
	self.theme = theme
	background = ColorRect.new()
	background.color = Color("10292b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	margin.add_child(column)
	title = Label.new()
	title.text = "輪迴 · 隔離動態試演 F5-B"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	body=BoxContainer.new()
	body.vertical=true
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var host := Control.new()
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(host)
	effect = Effect.new()
	host.add_child(effect)
	effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toolbar=GridContainer.new()
	toolbar.columns=6
	toolbar.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	toolbar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	body.add_child(toolbar)
	var first := toolbar
	_button(first,"pause","暫停",func():
		effect.paused = not effect.paused
		controls.pause.text = "繼續" if effect.paused else "暫停")
	_button(first,"reset","重播",func(): effect.clock=0.0; effect.apply_pose())
	_button(first,"speed","演出速度",func():
		effect.ceremonial=not effect.ceremonial
		controls.speed.text="演出速度" if effect.ceremonial else "常態速度")
	_button(first,"glow","柔光：開",func():
		effect.glow_enabled=not effect.glow_enabled
		controls.glow.text="柔光：開" if effect.glow_enabled else "柔光：關"
		effect.apply_pose())
	_button(first,"reduced","低特效：關",func():
		effect.reduced=not effect.reduced
		controls.reduced.text="低特效：開" if effect.reduced else "低特效：關"
		effect.apply_pose())
	var second := toolbar
	for mode in ["合成","裸盤","花光","雲霧","豎字"]:
		_button(second,mode,"直排字" if mode=="豎字" else mode,func(): effect.solo=mode; effect.apply_pose())
	_button(second,"background","紙／夜",func():
		paper=not paper
		background.color=Color("e4dbc8") if paper else Color("10292b")
		title.modulate=Color("183c38") if paper else Color.WHITE
		status.modulate=Color("183c38") if paper else Color.WHITE
		effect.paper=paper
		effect.apply_pose())
	status=Label.new()
	status.text="盤轉 · 花浮 · 霧流 · 直排上升 ｜ 視覺試作"
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size",16)
	column.add_child(status)
	resized.connect(_layout)
	_layout()
	print("F5B_READY isolated visual-only preview")

func _sync_web_css_size() -> void:
	# The browser canvas backing buffer includes DPR. Lay out controls in CSS px.
	var css_width := int(JavaScriptBridge.eval("window.innerWidth"))
	var css_height := int(JavaScriptBridge.eval("window.innerHeight"))
	if css_width>0 and css_height>0:
		get_window().content_scale_size=Vector2i(css_width,css_height)

func _on_web_resize() -> void:
	# Browser resize and the engine backing-buffer callback can arrive in one
	# event. Read CSS dimensions after the browser finishes that resize event.
	await get_tree().process_frame
	await get_tree().process_frame
	_sync_web_css_size()

func _layout() -> void:
	var compact := size.y<500
	body.vertical=not compact
	toolbar.columns=3 if compact else 6
	toolbar.size_flags_horizontal=Control.SIZE_SHRINK_CENTER if not compact else Control.SIZE_SHRINK_END

func _button(row: Container,id: String,text: String,action: Callable) -> void:
	var button := Button.new()
	button.text=text
	button.custom_minimum_size=Vector2(76,44)
	button.pressed.connect(action)
	row.add_child(button)
	controls[id]=button
