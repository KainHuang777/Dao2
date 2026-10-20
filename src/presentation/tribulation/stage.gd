extends Control
const ROOT = "res://assets/tribulation/trib-a/"
const CORES = {"hero_hover":Vector2(.57,.39),"hero_hit":Vector2(.58,.40),"hero_unbalanced":Vector2(.70,.42),"hero_recover":Vector2(.53,.39)}
var clock := 0.0
var paused := false
var failed := false
var reduced := false
var fisheye := true
var glow := true
var solo := "合成"
var viewport: SubViewport
var backdrop: TextureRect
var background := {}
var foreground := {}
var bolts: Array[Line2D] = []
var textures := {}
var core := Vector2.ZERO
var pose := "hero_hover"
var strike := 0.0
var finished := false
var branches: Array[Line2D] = []
signal ended

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	viewport=SubViewport.new()
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	for id in ["clean","star_arc","far_island","buddha","waterfall_left","waterfall_right","mist_far","terrain","ground_shadow"]:
		background[id]=sprite(id,viewport)
	backdrop=TextureRect.new()
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	backdrop.texture=viewport.get_texture()
	var mat := ShaderMaterial.new()
	mat.shader=load("res://src/presentation/tribulation/background.gdshader")
	backdrop.material=mat
	add_child(backdrop)
	for id in ["asura","shield_intact","shield_cracked","shield_shattered_v2","hero_recover","hero_hover","hero_hit","hero_unbalanced","hero_recover_emission","hero_hover_emission","hero_hit_emission","hero_unbalanced_emission","mist_near"]:
		foreground[id]=sprite(id,self)
		if id.ends_with("emission"):
			var emission := ShaderMaterial.new()
			emission.shader=load("res://src/presentation/tribulation/emission.gdshader")
			foreground[id].material=emission
	for width in [18.0,7.0,2.0]:
		var bolt := Line2D.new()
		bolt.width=width
		bolt.default_color=Color(.23,.53,1,.14) if width>10 else (Color(.35,.75,1,.55) if width>3 else Color(.9,.98,1))
		bolt.antialiased=true
		add_child(bolt)
		bolts.append(bolt)
	for i in 2:
		var branch := Line2D.new()
		branch.width=1.4
		branch.default_color=Color(.5,.8,1,.65)
		branch.antialiased=true
		add_child(branch)
		branches.append(branch)
	resized.connect(apply_pose)
	apply_pose()

func sprite(id: String,parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	var path := "res://assets/abode/fx3art1/terrain.png" if id=="terrain" else ROOT+id+".png"
	s.texture=load(path)
	textures[id]=s.texture
	parent.add_child(s)
	return s

func place(s: Sprite2D,uv: Vector2,height: float,alpha: float=1.0,anchor: Vector2=Vector2(.5,.5),extent: Vector2=Vector2.ZERO) -> void:
	var area := size if extent==Vector2.ZERO else extent
	var pixels := height*area.y
	s.scale=Vector2.ONE*pixels/s.texture.get_height()
	s.position=uv*area+(Vector2(.5,.5)-anchor)*s.texture.get_size()*s.scale
	s.modulate=Color(1,1,1,clampf(alpha,0,1))
	s.visible=alpha>0.001

func plate(id: String,alpha: float) -> void:
	var s: Sprite2D=background[id]
	var area := Vector2(viewport.size)
	var k := maxf(area.x/s.texture.get_width(),area.y/s.texture.get_height())*1.32
	s.scale=Vector2.ONE*k
	s.position=area*.5
	s.modulate=Color(.64,.72,.86,alpha)
	s.visible=alpha>0

func apply_pose() -> void:
	if not is_node_ready() or size.x<1 or size.y<1: return
	viewport.size=Vector2i((size*.5).ceil())
	backdrop.size=size
	var t := clampf(clock,0,20)
	var rise := smoothstep(2,6.5,t)*(1.0-smoothstep(16,19.5,t))
	var return_amount := smoothstep(16,19.5,t)
	var sky := smoothstep(4.8,6.8,t)*(1.0-smoothstep(15.8,18.5,t))
	if reduced: rise=0; sky=.65 if t>=7 and t<16 else 0
	plate("clean",1)
	plate("star_arc",sky)
	var area := Vector2(viewport.size)
	var retreat := rise if not reduced else 0.0
	place(background.far_island,Vector2(.18,.29+retreat*.34),.30,1-sky,Vector2(.5,.5),area)
	var buddha_at := Vector2(.80,.33+retreat*.62)
	place(background.buddha,buddha_at,.63, .70*(1-sky),Vector2(.5,.5),area)
	var buddha_top := buddha_at-Vector2(.315*area.y/area.x,.315)
	for item in [{"id":"waterfall_left","uv":Vector2(.365,.45),"anchor":Vector2(.51,.103)},{"id":"waterfall_right","uv":Vector2(.61,.41),"anchor":Vector2(.363,.10)}]:
		var eye: Vector2=(Vector2(64,64)+item.uv*896.0)/1024.0
		place(background[item.id],buddha_top+Vector2(eye.x*.63*area.y/area.x,eye.y*.63),.32,.7*(1-sky),item.anchor,area)
	place(background.mist_far,Vector2(.5+sin(t*.25)*.05,.67+retreat*.44),.46,.55*(1-sky),Vector2(.5,.5),area)
	place(background.terrain,Vector2(.49,.95+retreat*.82),.59,1,Vector2(.5,.5),area)
	place(background.ground_shadow,Vector2(.5,.83+retreat*.82),.08,.70*(1-rise),Vector2(.5,.5),area)
	var bend := sin(PI*clampf((t-2.5)/3.0,0,1))*.09 if fisheye and not reduced else 0.0
	backdrop.material.set_shader_parameter("bend",bend)
	backdrop.material.set_shader_parameter("aspect",size.x/size.y)
	strike=0
	for cue in [7.6,9.3,11.1]: strike=maxf(strike,1.0-smoothstep(0,.48,t-cue) if t>=cue else 0.0)
	pose="hero_recover" if t<2 or t>=18.8 else "hero_hover"
	if strike>.2: pose="hero_hit"
	if failed and t>=12.4: pose="hero_unbalanced"
	if not failed and t>=12.4: pose="hero_recover"
	core=Vector2(.5,lerpf(.61,.47,rise))*size
	if failed and t>=12.4 and t<18.8: core.y+=sin(clampf((t-12.4)/6.4,0,1)*PI)*size.y*.09
	if not reduced: core+=Vector2(sin(t*71)*strike*.007,sin(t*53)*strike*.004)*size.y
	for id in foreground: foreground[id].visible=false
	var actor_height := .46
	var anchor: Vector2=(Vector2(64,64)+CORES[pose]*896.0)/1024.0
	place(foreground[pose],core/size,actor_height,1,anchor)
	if glow:
		place(foreground[pose+"_emission"],core/size,actor_height,.25+strike*.75,anchor)
		foreground[pose+"_emission"].material.set_shader_parameter("strength",.3+strike*2.0)
	var shield := "shield_intact" if t<9 else "shield_cracked"
	if t>=12.4: shield="shield_shattered_v2" if failed else "shield_intact"
	var shield_alpha := smoothstep(4.5,7,t)*(1.0-smoothstep(15,18,t))
	place(foreground[shield],core/size+Vector2(0,.075),.62,shield_alpha*(.4+strike*.35))
	if failed:
		place(foreground.asura,Vector2(.5,.40+return_amount*.20),.95,smoothstep(12,13.5,t)*(1-smoothstep(16,19.5,t))*.5)
	place(foreground.mist_near,Vector2(.5+sin(t*.7)*.09,.98-rise*.08),.42,.5*(1-sky)+sin(sky*PI)*.4)
	for bolt in bolts:
		bolt.visible=strike>.02 and not reduced and solo in ["合成","雷擊"]
		bolt.modulate.a=strike
		var points := PackedVector2Array()
		for i in 19:
			var ratio := float(i)/18
			points.append(Vector2(core.x+sin(i*2.7+floor(t*18))*.018*size.y*(1-ratio),lerpf(size.y*.02,core.y,ratio)))
		points[-1]=core
		bolt.points=points
	for i in 2:
		var branch: Line2D=branches[i]
		branch.visible=bolts[0].visible
		branch.modulate.a=strike
		var side := -1.0 if i==0 else 1.0
		branch.points=PackedVector2Array([core,core+Vector2(side*.07,-.06)*size.y,core+Vector2(side*.10,-.14)*size.y,core+Vector2(side*.15,-.18)*size.y])
	if solo!="合成":
		backdrop.visible=solo=="背景"
		for id in foreground:
			foreground[id].visible=foreground[id].visible and ((solo=="人物" and id.begins_with("hero")) or (solo=="護體" and id.begins_with("shield")) or (solo=="修羅" and id=="asura"))
	else: backdrop.visible=true
	if reduced:
		foreground.mist_near.visible=false
		foreground[pose+"_emission"].visible=false
	queue_redraw()

func _draw() -> void:
	# Solid isolation background for solo layers, below children.
	draw_rect(Rect2(Vector2.ZERO,size),Color("091224"))

func _process(delta: float) -> void:
	if paused or not is_visible_in_tree() or finished: return
	clock=minf(20,clock+delta)
	apply_pose()
	if clock>=20:
		finished=true
		ended.emit()

func seek(value: float) -> void:
	clock=clampf(value,0,20)
	finished=clock>=20
	apply_pose()
