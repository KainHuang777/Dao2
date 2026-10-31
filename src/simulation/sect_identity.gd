class_name SectIdentity
extends RefCounted
## Identity-only feature; does not activate the complete sect reform migration.
const VERSION := 1
const NAMES := {
	"taixu_sect": "太虛天闕",
	"tianjian_sect": "天劍聖宗",
	"piaomiao_sect": "縹緲仙宮",
	"wanfo_sect": "萬佛靈宗",
	"zixiao_sect": "紫霄玄門",
}

static func canonical_id(value: String) -> String:
	if NAMES.has(value): return value
	for id in NAMES:
		if NAMES[id] == value: return id
	return ""

static func view(sect: Dictionary) -> Dictionary:
	var joined := bool(sect.get("unlocked", false))
	var id := ""
	if joined:
		# Legacy IDs were always taixu, even after choosing a different sect.
		if sect.get("identity_version", 0) == VERSION:
			id = String(sect.get("sect_id", ""))
		else:
			for legacy_id in NAMES:
				if sect.get("sect_name", "") == NAMES[legacy_id]: id = legacy_id
	return {"sect_id": id, "sect_name": NAMES.get(id, ""), "identity_pending": joined and id.is_empty(), "unlocked": joined}

static func write(sect: Dictionary, id: String) -> void:
	sect.identity_version = VERSION
	sect.sect_id = id
	sect.sect_name = NAMES[id]

static func validate(sect: Dictionary) -> String:
	if not sect.has("identity_version"): return "" # Untouched legacy snapshots.
	var version: Variant = sect.identity_version
	if not (version is int or version is float) or version is bool or version != VERSION: return "SECT_IDENTITY_VERSION"
	var id: Variant = sect.get("sect_id", "")
	if not (id is String): return "SECT_IDENTITY_ID"
	if not bool(sect.get("unlocked", false)):
		return "" if id.is_empty() else "SECT_IDENTITY_MEMBERSHIP"
	if not NAMES.has(id): return "SECT_IDENTITY_ID"
	if sect.get("sect_name") != NAMES[id]: return "SECT_IDENTITY_NAME"
	return ""
