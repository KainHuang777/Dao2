extends SceneTree
const BASE = "res://docs/verification/artifacts/uix-r7-f5b-f1/"
const DEST = "res://assets/ui/reincarnation-layered-f5b-f1/"
func _initialize() -> void:
	var source := Image.load_from_file(BASE+"originals/disc_face.png")
	# Register the opaque plate, excluding faint stray alpha outside the rim.
	var minimum := Vector2i(source.get_width(),source.get_height())
	var maximum := Vector2i.ZERO
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a>0.5:
				minimum=minimum.min(Vector2i(x,y))
				maximum=maximum.max(Vector2i(x,y))
	var bounds := Rect2i(minimum,maximum-minimum+Vector2i.ONE)
	var plate := source.get_region(bounds)
	plate.resize(560,560,Image.INTERPOLATE_LANCZOS)
	var result := Image.create(1024,1024,false,Image.FORMAT_RGBA8)
	result.blend_rect(plate,Rect2i(0,0,560,560),Vector2i(232,232))
	var err := result.save_png(DEST+"disc_face.png")
	var holes := 0
	for y in range(282,743):
		for x in range(282,743):
			if Vector2(x-512,y-512).length()<225 and result.get_pixel(x,y).a<0.97: holes+=1
	var record={"task":"UIX-R7-F5-B-F1","source":BASE+"originals/disc_face.png","source_sha256":FileAccess.get_sha256(BASE+"originals/disc_face.png"),"output_sha256":FileAccess.get_sha256(DEST+"disc_face.png"),"source_opaque_bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"registration_rect":[232,232,560,560],"pivot":[512,512],"aperture_holes":holes,"license":"Built-in ImageGen repaint from project AI asset; no external image copied","checks":"registration and alpha coverage only; rendered rotation needs visual review"}
	FileAccess.open(DEST+"manifest.json",FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("F5BF1_ASSETS ",JSON.stringify(record))
	quit(0 if err==OK and holes==0 else 1)
