extends GutTest
## Escena del jugador: montaje (capas, cámara, máquina de estados) y caída hasta el suelo.

const PlayerScene := preload("res://entities/player/player.tscn")
const SPAWN_HEIGHT := 2.0

var _player: Player


func before_each() -> void:
	_add_ground()
	_player = PlayerScene.instantiate() as Player
	_player.position = Vector3(0.0, SPAWN_HEIGHT, 0.0)
	add_child_autofree(_player)


func test_body_is_the_player_and_collides_with_the_world() -> void:
	assert_eq(_player.collision_layer, PhysicsLayers.mask(PhysicsLayers.PLAYER))
	assert_eq(_player.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))


func test_camera_follows_the_player_and_only_collides_with_the_world() -> void:
	var rig := _player.get_node(^"CameraRig") as CameraRig
	assert_same(rig.target, _player)
	var arm := rig.get_node(^"%SpringArm3D") as SpringArm3D
	assert_eq(arm.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))


func test_falls_and_lands_on_the_ground() -> void:
	assert_same(_player.movement.current, _player.air_state, "empieza en el aire")
	await wait_physics_frames(60)
	assert_true(_player.is_on_floor(), "ha aterrizado")
	assert_same(_player.movement.current, _player.ground_state)
	assert_almost_eq(_player.global_position.y, 0.0, 0.05)


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 1.0, 20.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
