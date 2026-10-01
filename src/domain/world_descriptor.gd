class_name WorldDescriptor
extends RefCounted

## WorldDescriptor
## Pure RefCounted data structure modeling a generated world / region / landmark node.
## Strictly decoupled from Nodes, Shaders, Textures, and UI.

var address: WorldAddress = null
var generator_version: int = 1
var name: String = ""
var description: String = ""
var realm_id: String = "realm_human"
var scale_tier: int = WorldAddress.ScaleTier.REGION
var qi_density: float = 1.0
var danger_level: int = 1
var dominant_element: String = "earth"
var environment_traits: Array = []
var resource_tags: Array = []
var resource_bias: Dictionary = {}
var special_features: Array = []

func _init(p_addr: WorldAddress = null) -> void:
	if p_addr != null:
		address = p_addr.duplicate_address()
		realm_id = p_addr.world_id
	else:
		address = WorldAddress.default_home()
		realm_id = address.world_id

func is_valid() -> bool:
	return address != null and address.is_valid() and not name.is_empty() and qi_density > 0.0

func to_dict() -> Dictionary:
	return {
		"address": address.to_address_string() if address != null else "",
		"generator_version": generator_version,
		"name": name,
		"description": description,
		"realm_id": realm_id,
		"scale_tier": scale_tier,
		"qi_density": qi_density,
		"danger_level": danger_level,
		"dominant_element": dominant_element,
		"environment_traits": environment_traits.duplicate(true),
		"resource_tags": resource_tags.duplicate(true),
		"resource_bias": resource_bias.duplicate(true),
		"special_features": special_features.duplicate(true),
	}

static func from_dict(d: Dictionary) -> WorldDescriptor:
	var desc := WorldDescriptor.new()
	if d.has("address"):
		desc.address = WorldAddress.parse(String(d["address"]))
	else:
		desc.address = WorldAddress.default_home()
	desc.generator_version = int(d.get("generator_version", 1))
	desc.name = String(d.get("name", ""))
	desc.description = String(d.get("description", ""))
	desc.realm_id = String(d.get("realm_id", desc.address.world_id))
	desc.scale_tier = int(d.get("scale_tier", WorldAddress.ScaleTier.REGION))
	desc.qi_density = float(d.get("qi_density", 1.0))
	desc.danger_level = int(d.get("danger_level", 1))
	desc.dominant_element = String(d.get("dominant_element", "earth"))
	desc.environment_traits = (d.get("environment_traits", []) as Array).duplicate(true)
	desc.resource_tags = (d.get("resource_tags", []) as Array).duplicate(true)
	desc.resource_bias = (d.get("resource_bias", {}) as Dictionary).duplicate(true)
	desc.special_features = (d.get("special_features", []) as Array).duplicate(true)
	return desc

func duplicate_descriptor() -> WorldDescriptor:
	return WorldDescriptor.from_dict(to_dict())

func _to_string() -> String:
	return "[WorldDescriptor: %s (%s) @ %s, qi=%.2f, tier=%d]" % [name, realm_id, address.to_address_string() if address != null else "null", qi_density, scale_tier]
