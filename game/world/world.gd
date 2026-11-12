extends Node3D

const LanderScript := preload("res://world/lander.gd")

@onready var ground: Node3D = $Ground
@onready var rocks: Node3D = $Rocks
@onready var base: Node3D = $Base
@onready var crew: Node3D = $Crew
@onready var sky_rig: Node3D = $SkyRig
@onready var camera_rig: Node3D = $CameraRig
@onready var effects: Node3D = $Effects
@onready var lander: Node3D = $Lander

func _ready() -> void:
	pass


