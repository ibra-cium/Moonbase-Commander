class_name ModelCatalog
extends RefCounted

# Cargo item models per ART_DIRECTION §3
const SCENE_SOLAR: PackedScene = preload("res://assets/models/kaykit/solarpanel.gltf")
const SCENE_BATTERY: PackedScene = preload("res://assets/models/kaykit/containers_B.gltf")
const SCENE_GREENHOUSE: PackedScene = preload("res://assets/models/kaykit/basemodule_E.gltf")
const SCENE_O2: PackedScene = preload("res://assets/models/kaykit/containers_A.gltf")
const SCENE_WATER: PackedScene = preload("res://assets/models/kaykit/containers_C.gltf")
const SCENE_FOOD: PackedScene = preload("res://assets/models/kaykit/cargo_A_stacked.gltf")
const SCENE_FOOD_PACKED: PackedScene = preload("res://assets/models/kaykit/cargo_A_packed.gltf")
const SCENE_FOOD_SINGLE: PackedScene = preload("res://assets/models/kaykit/cargo_A.gltf")
const SCENE_REACTOR_BASE: PackedScene = preload("res://assets/models/kaykit/lander_base.gltf")

# Base infrastructure models
const SCENE_HABITAT: PackedScene = preload("res://assets/models/kaykit/basemodule_A.gltf")
const SCENE_LIFESUPPORT: PackedScene = preload("res://assets/models/kaykit/basemodule_C.gltf")
const SCENE_TUNNEL_STRAIGHT: PackedScene = preload("res://assets/models/kaykit/tunnel_straight_A.gltf")
const SCENE_TUNNEL_STRAIGHT_B: PackedScene = preload("res://assets/models/kaykit/tunnel_straight_B.gltf")
const SCENE_TUNNEL_DIAGONAL: PackedScene = preload("res://assets/models/kaykit/tunnel_diagonal_short_A.gltf")
const SCENE_SHELTER: PackedScene = preload("res://assets/models/kaykit/tunnel_straight_B.gltf")
const SCENE_DRILL: PackedScene = preload("res://assets/models/kaykit/drill_structure.gltf")
const SCENE_LIGHTS: PackedScene = preload("res://assets/models/kaykit/lights.gltf")
const SCENE_ROVER: PackedScene = preload("res://assets/models/kaykit/spacetruck.gltf")
const SCENE_TRAILER: PackedScene = preload("res://assets/models/kaykit/spacetruck_trailer.gltf")
const SCENE_RADAR: PackedScene = preload("res://assets/models/quaternius/roof_radar.gltf")
const SCENE_LANDINGPAD: PackedScene = preload("res://assets/models/kaykit/landingpad_small.gltf")
const SCENE_DIG_SITE: PackedScene = preload("res://assets/models/kaykit/terrain_mining.gltf")

const CARGO_MAP := {
	"solar": SCENE_SOLAR,
	"battery": SCENE_BATTERY,
	"greenhouse": SCENE_GREENHOUSE,
	"o2": SCENE_O2,
	"water": SCENE_WATER,
	"food": SCENE_FOOD,
}

const BASE_MAP := {
	"habitat": SCENE_HABITAT,
	"lifesupport": SCENE_LIFESUPPORT,
	"tunnel_straight": SCENE_TUNNEL_STRAIGHT,
	"tunnel_straight_b": SCENE_TUNNEL_STRAIGHT_B,
	"tunnel_diagonal": SCENE_TUNNEL_DIAGONAL,
	"shelter": SCENE_SHELTER,
	"drill": SCENE_DRILL,
	"lights": SCENE_LIGHTS,
	"rover": SCENE_ROVER,
	"trailer": SCENE_TRAILER,
	"radar": SCENE_RADAR,
	"landingpad": SCENE_LANDINGPAD,
	"dig_site": SCENE_DIG_SITE,
	"reactor_base": SCENE_REACTOR_BASE,
}

static func get_cargo_scene(key: String) -> PackedScene:
	return CARGO_MAP.get(key, null)

static func get_base_scene(key: String) -> PackedScene:
	return BASE_MAP.get(key, null)

static func instantiate_model(key: String) -> Node3D:
	var scene: PackedScene = CARGO_MAP.get(key, null)
	if scene == null:
		scene = BASE_MAP.get(key, null)
	if scene != null:
		return scene.instantiate() as Node3D
	return null

static func set_shadows_enabled(node: Node, enabled: bool) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)
	for child in node.get_children():
		set_shadows_enabled(child, enabled)

