extends GutTest
## Acciones del jugador con física real: dash, picado (doble Shift en el aire sin dirección) y
## doble salto, con su gasto de stamina.

const PlayerScene := preload("res://entities/player/player.tscn")
const SETTLE_FRAMES := 5
const CHARGE_TOLERANCE := 0.05

var _player: Player
var _move: MovementData


func before_each() -> void:
	_add_ground()
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_move = _player.stats.get_resolved(MovementData) as MovementData


func test_dash_goes_fast_where_the_camera_looks_and_spends_a_charge() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	var max_charges := _player.stamina.get_max_charges()
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(2)
	var velocity := _player.velocity
	assert_almost_eq(Vector2(velocity.x, velocity.z).length(), _move.dash_speed, 0.01)
	assert_lt(velocity.z, 0.0, "sin dirección, hacia donde mira la cámara (−Z)")
	assert_almost_eq(_player.stamina.get_charges(), max_charges - _move.dash_cost, CHARGE_TOLERANCE)


func test_no_dash_without_stamina() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.stamina.spend(_player.stamina.get_charges())
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(2)
	assert_same(_player.movement.current, _player.ground_state)
	assert_almost_eq(_player.velocity.length(), 0.0, 0.01)


func test_double_shift_in_the_air_without_direction_dives() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(10)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(3)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(1)
	assert_true(_player.movement.current is DownDashState, "el segundo Shift es el picado")
	assert_almost_eq(_player.velocity.y, -_move.down_dash_speed, 0.01)
	await wait_physics_frames(30)
	assert_same(_player.movement.current, _player.ground_state, "aterriza")


func test_double_jump_goes_higher_than_a_single_jump() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(18)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(2)
	assert_eq(_player.context.air_jumps_used, 1, "gastó el salto en el aire")
	# Cada espera de 1 frame de GUT avanza unos 2 ticks: 30 vueltas dan para subir y caer.
	var highest := _player.global_position.y
	for _frame: int in 30:
		await wait_physics_frames(1)
		highest = maxf(highest, _player.global_position.y)
	assert_gt(highest, _move.jump_height + 1.0, "el segundo salto suma altura")


func test_landing_gives_the_double_jump_back() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(10)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(60)
	assert_same(_player.movement.current, _player.ground_state)
	assert_eq(_player.context.air_jumps_used, 0)


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
