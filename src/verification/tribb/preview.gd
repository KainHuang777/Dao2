extends Control
const Stage=preload("res://stage.gd")
const Sound=preload("res://sound.gd")
var effect: Control
var controls := {}
var slider: HSlider
var status: Label
var body: BoxContainer
var panel: VBoxContainer
var audio: AudioStreamPlayer
var streams := []
var muted := true
var focused := true
var rotation_hint: Label
var grid: GridContainer

func _ready() -> void:
	var theme := Theme.new()
	var font := FontVariation.new()
	font.base_font=load("res://assets/fonts/runtime/Dao2Sans-VF.ttf")
	font.variation_opentype={"wght":600}
	theme.default_font=font
	theme.default_font_size=18
	self.theme=theme
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,8)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	status=Label.new()
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	body=BoxContainer.new()
	body.size_flags_vertical=SIZE_EXPAND_FILL
	column.add_child(body)
	effect=Stage.new()
	effect.custom_minimum_size=Vector2(200,120)
	effect.size_flags_horizontal=SIZE_EXPAND_FILL
	effect.size_flags_vertical=SIZE_EXPAND_FILL
	body.add_child(effect)
	panel=VBoxContainer.new()
	body.add_child(panel)
	grid=GridContainer.new()
	grid.columns=3
	panel.add_child(grid)
	button(grid,"outcome","成功試演",func():
		effect.failed=not effect.failed
		controls.outcome.text="失敗試演" if effect.failed else "成功試演"
		restart())
	button(grid,"pause","暫停",func():
		effect.paused=not effect.paused
		controls.pause.text="繼續" if effect.paused else "暫停"
		sync_audio())
	button(grid,"replay","重播",restart)
	button(grid,"fisheye","魚眼：開",func():
		effect.fisheye=not effect.fisheye
		controls.fisheye.text="魚眼：開" if effect.fisheye else "魚眼：關"
		effect.apply_pose())
	button(grid,"glow","泛光：開",func():
		effect.glow=not effect.glow
		controls.glow.text="泛光：開" if effect.glow else "泛光：關"
		effect.apply_pose())
	button(grid,"sound","音效：關",func():
		muted=not muted
		controls.sound.text="音效：關" if muted else "音效：開"
		sync_audio())
	button(grid,"reduced","低特效：關",func():
		effect.reduced=not effect.reduced
		controls.reduced.text="低特效：開" if effect.reduced else "低特效：關"
		effect.apply_pose())
	button(grid,"skip","跳過",func(): effect.seek(20); sync_audio())
	button(grid,"layer","圖層：合成",func():
		var layers := ["合成","背景","人物","護體","雷擊","修羅"]
		effect.solo=layers[(layers.find(effect.solo)+1)%layers.size()]
		controls.layer.text="圖層："+effect.solo
		effect.apply_pose())
	slider=HSlider.new()
	slider.max_value=20
	slider.step=.01
	slider.custom_minimum_size=Vector2(0,44)
	panel.add_child(slider)
	slider.value_changed.connect(func(value): effect.seek(value); sync_audio())
	var note := Label.new()
	note.text="隔離試演 · 無收益 · 拖動時間軸定位"
	note.add_theme_font_size_override("font_size",16)
	panel.add_child(note)
	audio=AudioStreamPlayer.new()
	audio.volume_db=-5
	add_child(audio)
	streams=[Sound.make(false),Sound.make(true)]
	effect.ended.connect(sync_audio)
	rotation_hint=Label.new()
	rotation_hint.text="請將視窗轉為橫式以查看渡劫試演"
	rotation_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	rotation_hint.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	rotation_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rotation_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rotation_hint)
	resized.connect(layout)
	if OS.has_feature("web"):
		get_window().size_changed.connect(web_resize)
		web_resize()
	layout()
	print("TRIBB_READY isolated, no Session, 20 seconds, sound muted by default")

func button(parent: Node,id: String,caption: String,action: Callable) -> void:
	var b := Button.new()
	b.text=caption
	b.custom_minimum_size=Vector2(100,44)
	b.pressed.connect(action)
	parent.add_child(b)
	controls[id]=b

func layout() -> void:
	body.vertical=size.y>=500
	panel.custom_minimum_size.x=316 if size.y<500 else 0
	grid.columns=9 if size.y>=500 and size.x>=1000 else 3
	rotation_hint.visible=size.x<size.y
	body.visible=not rotation_hint.visible
	if is_instance_valid(audio): sync_audio()

func web_resize() -> void:
	await get_tree().process_frame
	get_window().content_scale_size=Vector2i(int(JavaScriptBridge.eval("innerWidth")),int(JavaScriptBridge.eval("innerHeight")))
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE

func restart() -> void:
	effect.paused=false
	controls.pause.text="暫停"
	effect.seek(0)
	sync_audio()

func sync_audio() -> void:
	if not is_instance_valid(audio): return
	audio.stop()
	if muted or effect.paused or effect.finished or not focused or not effect.is_visible_in_tree(): return
	audio.stream=streams[1 if effect.failed else 0]
	audio.play(effect.clock)

func _process(_delta: float) -> void:
	if not is_instance_valid(effect): return
	slider.set_value_no_signal(effect.clock)
	var phase: String=["劫兆","離塵","天幕","受劫","分歧","回返"][0 if effect.clock<2 else 1 if effect.clock<5 else 2 if effect.clock<7 else 3 if effect.clock<12.4 else 4 if effect.clock<16 else 5]
	status.text="渡劫 · %s · %04.1f / 20 秒 · %s" % [phase,effect.clock,"修羅失敗" if effect.failed else "成功"]
	if effect.finished: status.text="試演結束 · "+("失敗回返" if effect.failed else "成功回返")

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused=false
		if is_instance_valid(effect): effect.paused=true; controls.pause.text="繼續"
		if is_instance_valid(audio): audio.stop()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN: focused=true
	elif what==NOTIFICATION_VISIBILITY_CHANGED and is_instance_valid(audio):
		if not is_visible_in_tree(): audio.stop()

func _exit_tree() -> void:
	if is_instance_valid(audio): audio.stop()
