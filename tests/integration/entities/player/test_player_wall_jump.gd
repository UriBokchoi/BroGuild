extends GutTest
## Salto en pared con física real: junto a una pared, en el aire, Espacio separa de la pared hacia
## arriba sin gastar el doble salto; el primero es gratis y el encadenado cuesta media carga.

const PlayerScene := preload("res://entities/player/player.tscn")
const SETTLE_FRAMES := 5
## La cara de la pared queda en x = 1,5; el jugador, en x = 1 (a 0,1 m de tocarla).
const WALL_FACE_X := 1.5
const PLAYER_X := 1.0

var _player: Player
var _move: MovementData


func before_each() -> void:
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(40.0, 1.0, 40.0))
	_add_box(Vector3(WALL_FACE_X + 0.5, 5.0, 0.0), Vector3(1.0, 10.0, 10.0))
	_player = PlayerScene.instantiate() as Player
	_player.position = Vector3(PLAYER_X, 0.0, 0.0)
	add_child_autofree(_player)
	_move = _player.stats.get_resolved(MovementData) as MovementData


func test_kicks_off_the_wall_upwards_for_free() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	var charges := _player.stamina.get_charges()
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(6)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(2)
	assert_eq(_player.context.wall_jumps_chained, 1, "salto en pared")
	assert_eq(_player.context.air_jumps_used, 0, "no gasta el doble salto")
	assert_lt(_player.velocity.x, 0.0, "se separa de la pared (hacia −X)")
	assert_gt(_player.velocity.y, 0.0, "hacia arriba")
	assert_almost_eq(_player.stamina.get_charges(), charges, 0.05, "el primero es gratis")


func test_chained_wall_jump_costs_half_a_charge() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(6)
	var charges := _player.stamina.get_charges()
	# Dos pulsaciones seguidas: entra una por tick y el segundo tick sigue junto a la pared.
	_player.movement.request(InputActions.JUMP)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(3)
	assert_eq(_player.context.wall_jumps_chained, 2)
	assert_between(_player.stamina.get_charges(), charges - _move.wall_jump_chain_cost, charges - _move.wall_jump_chain_cost + 0.05)


func _add_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.position = center
	body.add_child(shape)
	add_child_autofree(body)
