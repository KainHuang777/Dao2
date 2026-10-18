extends Control
## Accepted F5-B-F2 layers, hosted by the formal presentation. No gameplay state.
const IDS = ["mist_back","disc_face","disc_rim_fixed","tassels","lotus","lotus_emission","light_ribbon","mist_front_left","mist_front_right"]
const WORDS = ["天人","人間","修羅","畜生","餓鬼","地獄"]
const SANSKRIT = ["ॐ","मणि","पद्मे","हूँ"]
const GlyphGlow = preload("res://src/presentation/reincarnation_fx/glyph_glow.gdshader")
const Glow = preload("res://src/presentation/reincarnation_fx/local_glow.gdshader")
const Mist = preload("res://src/presentation/reincarnation_fx/mist.gdshader")
var clock := 0.0
var paused := true
var reduced := false
var glow_enabled := true
var ceremonial := false
var paper := false
var solo := "合成"
var canvas := Node2D.new()
var projection := Node2D.new()
var rotor: Sprite2D
var layers := {}
var glyphs: Array[Sprite2D] = []
var caches: Array[SubViewport] = []
var ready_for_capture := false
var font: Font = UiTypography.reincarnation_font()
var sanskrit_font: Font = UiTypography.reincarnation_mantra_font()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	for id in IDS:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/ui/reincarnation-layered-f5a/"+id+".png")
		if id=="disc_face": sprite.texture=load("res://assets/ui/reincarnation-layered-f5b-f1/disc_face.png")
		layers[id] = sprite
		if id == "disc_face":
			canvas.add_child(projection)
			projection.position = Vector2(512,450)
			projection.scale = Vector2(962.0/1024.0,922.0/1024.0)
			projection.add_child(sprite)
			rotor = sprite
			# Keep the existing candidate size; the plate draws above the housing.
			sprite.scale=Vector2.ONE*0.86
		elif id == "disc_rim_fixed":
			projection.add_child(sprite)
			# User's option 2: only swap these two siblings, not lotus/mist order.
			projection.move_child(rotor,projection.get_child_count()-1)
			# Registered alpha opening center is (517.5,500.5), not (512,512).
			sprite.offset=Vector2(-5.5,11.5)
		else:
			canvas.add_child(sprite)
			sprite.position = Vector2(512,512)
		if id == "lotus_emission":
			sprite.material = ShaderMaterial.new()
			sprite.material.shader = Glow
			sprite.material.set_shader_parameter("radius_px",12.0)
		elif id.begins_with("mist"):
			sprite.material = ShaderMaterial.new()
			sprite.material.shader = Mist
			sprite.material.set_shader_parameter("direction",-1.0 if id.ends_with("right") else 1.0)
	for i in WORDS.size():
		# Cache the whole column; preserve Sanskrit shaping within each word.
		var vp := SubViewport.new()
		vp.size = Vector2i(192,480)
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(vp)
		caches.append(vp)
		var label := Label.new()
		label.text = WORDS[i][0]+"\n"+WORDS[i][1]
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",60)
		label.add_theme_constant_override("line_spacing",0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(44,24)
		label.size = Vector2(104,148)
		vp.add_child(label)
		var mantra := Label.new()
		mantra.text="\n".join(SANSKRIT)
		mantra.add_theme_font_override("font",sanskrit_font)
		mantra.add_theme_font_size_override("font_size",38)
		mantra.add_theme_constant_override("line_spacing",4)
		mantra.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		mantra.position=Vector2(30,178)
		mantra.size=Vector2(132,254)
		vp.add_child(mantra)
		var glyph := Sprite2D.new()
		glyph.texture = vp.get_texture()
		glyph.material = ShaderMaterial.new()
		glyph.material.shader = GlyphGlow
		canvas.add_child(glyph)
		glyphs.append(glyph)
	await RenderingServer.frame_post_draw
	for vp in caches: vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	ready_for_capture = true
	resized.connect(_layout)
	visibility_changed.connect(_visibility)
	_layout()
	apply_pose()

func _visibility() -> void:
	set_process(false)

func _layout() -> void:
	var extent := minf(size.x,size.y)
	canvas.scale = Vector2.ONE * extent / 1024.0
	canvas.position = (size-Vector2.ONE*extent)*0.5

func _process(delta: float) -> void:
	if paused or reduced or not is_visible_in_tree(): return
	clock += minf(delta,0.1)
	apply_pose()

func apply_pose() -> void:
	if rotor == null: return
	var t := 0.0 if reduced else clock
	rotor.rotation = t*TAU/(8.0 if ceremonial else 36.0)
	var bob := sin(t*TAU/3.6)*14.0
	layers.lotus.position.y = 512+bob
	layers.lotus_emission.position.y = 512+bob
	layers.lotus_emission.material.set_shader_parameter("strength",(0.35+0.65*(0.5+0.5*sin(t*TAU/3.6))) if glow_enabled else 0.0)
	layers.lotus_emission.visible = glow_enabled
	for id in ["mist_back","mist_front_left","mist_front_right"]:
		var sign_value := -1.0 if id == "mist_back" or id == "mist_front_right" else 1.0
		var period := 13.0 if id == "mist_back" else 9.0
		layers[id].position.x = 512 + sign_value*sin(t*TAU/period)*34.0
		layers[id].material.set_shader_parameter("effect_time",t)
	layers.light_ribbon.modulate.a = 0.64+0.16*sin(t*1.5)
	for i in glyphs.size():
		var age := fposmod(t-float(i)*1.3,7.8)
		var phase := age/3.6
		var glyph := glyphs[i]
		glyph.position = Vector2([150,880,300,730,150,880][i],760-phase*500)
		glyph.scale = Vector2.ONE*0.86
		glyph.modulate.a = smoothstep(0.0,0.13,phase)*(1.0-smoothstep(0.85,1.0,phase))
		if reduced:
			glyph.position = Vector2(190+float(i)*125,320)
			glyph.modulate.a = 1.0
		glyph.material.set_shader_parameter("strength",4.5 if glow_enabled else 0.0)
		glyph.material.set_shader_parameter("dark_ink",paper)
		glyph.material.set_shader_parameter("dissolve",smoothstep(0.82,1.0,phase) if not reduced else 0.0)
		glyph.visible = minf(size.x,size.y) >= 150.0 and (solo == "合成" or solo == "豎字") and (age<3.6 or reduced)
	for id in IDS:
		var shown: bool = solo == "合成" or (solo == "裸盤" and id in ["disc_face","disc_rim_fixed","tassels"]) or (solo == "花光" and id in ["lotus","lotus_emission"]) or (solo == "雲霧" and id.begins_with("mist"))
		layers[id].visible = shown and (id != "lotus_emission" or glow_enabled)
	queue_redraw()

func _draw() -> void:
	if minf(size.x,size.y) < 150.0 or reduced or solo not in ["合成","豎字"]: return
	# Deterministic decorative ink motes; no gameplay RNG.
	var extent := minf(size.x,size.y)
	var origin := (size-Vector2.ONE*extent)*0.5
	for i in 24:
		var phase := fposmod(clock*0.18+float(i)*0.137,1.0)
		var p := Vector2(0.2+fposmod(float(i)*0.173,0.6),0.8-phase*0.6)
		draw_circle(origin+p*extent,1.0 if i%3 else 1.8,Color(0.78,0.72,0.45,sin(phase*PI)*0.4))
