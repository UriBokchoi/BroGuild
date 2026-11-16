extends GutTest
## Teletransporte: con física real, el jugador que cae en la plataforma aparece en su destino,
## parado.

const PlayerScene := preload("res://entities/player/player.tscn")
const TeleporterScene := preload("res://entities/interactables/teleporter/teleporter.tscn")
const DESTINATION := Vector3(12.0, 0.0, 0.0)

var _teleporter: Teleporter


func before_each() -> void:
	_add_ground()
	var destination := Marker3D.new()
	destination.position = DESTINATION
	add_child_autofree(destination)
	_teleporter = TeleporterScene.instantiate() as Teleporter
	_teleporter.destination = destination
	_teleporter.label_key = &"TELEPORT_TO_COMBAT"
	add_child_autofree(_teleporter)


func test_shows_its_label() -> void:
	assert_eq(_teleporter.label.text, "TELEPORT_TO_COMBAT")


func test_sends_the_player_to_its_destination() -> void:
	watch_signals(_teleporter)
	var player := PlayerScene.instantiate() as Player
	player.position = Vector3(0.0, 1.0, 0.0)
	add_child_autofree(player)
	await wait_physics_frames(30)
	assert_signal_emitted(_teleporter, "teleported")
	assert_almost_eq(player.global_position.x, DESTINATION.x, 0.1)
	assert_almost_eq(player.global_position.z, DESTINATION.z, 0.1)


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
