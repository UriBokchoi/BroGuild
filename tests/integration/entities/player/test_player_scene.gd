extends GutTest
## Escena del jugador: capas de física y cámara montadas como dicen las constantes.

const PlayerScene := preload("res://entities/player/player.tscn")

var _player: CharacterBody3D


func before_each() -> void:
	_player = PlayerScene.instantiate() as CharacterBody3D
	add_child_autofree(_player)


func test_body_is_the_player_and_collides_with_the_world() -> void:
	assert_eq(_player.collision_layer, PhysicsLayers.mask(PhysicsLayers.PLAYER))
	assert_eq(_player.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))


func test_camera_follows_the_player_and_only_collides_with_the_world() -> void:
	var rig := _player.get_node(^"CameraRig") as CameraRig
	assert_same(rig.target, _player)
	var arm := rig.get_node(^"%SpringArm3D") as SpringArm3D
	assert_eq(arm.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))
