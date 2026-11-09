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


func test_jump_at_the_end_of_a_ground_dash_is_a_long_dash_jump() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	var max_charges := _player.stamina.get_max_charges()
	_player.movement.request(InputActions.DASH)
	# En los últimos 0,1 s del dash: la pulsación se guarda y sale al acabar.
	await wait_physics_frames(9)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(6)
	assert_true(_player.movement.current is AirState, "en el aire")
	assert_gt(_player.velocity.y, 0.0, "subiendo")
	assert_almost_eq(_horizontal_speed(), _move.dash_speed, 1.0, "con la velocidad del dash")
	# Gastó dash + dash-jump; desde entonces ha recargado unos ticks (menos de 0,2 cargas).
	var left := max_charges - _move.dash_cost - _move.dash_jump_cost
	assert_between(_player.stamina.get_charges(), left, left + 0.2)


func test_jump_after_the_window_is_a_normal_jump() -> void:
	await wait_physics_frames(SETTLE_FRAMES)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(40)
	_player.movement.request(InputActions.JUMP)
	await wait_physics_frames(2)
	assert_gt(_player.velocity.y, 0.0, "salta")
	assert_lt(_horizontal_speed(), _move.dash_exit_speed, "sin la velocidad del dash")


func test_ring_shows_only_while_the_dash_jump_window_is_open() -> void:
	var ring := _player.get_node(^"DashJumpRing") as Node3D
	await wait_physics_frames(SETTLE_FRAMES)
	assert_false(ring.visible)
	_player.movement.request(InputActions.DASH)
	await wait_physics_frames(14)
	assert_true(ring.visible, "justo al acabar el dash")
	await wait_physics_frames(30)
	assert_false(ring.visible, "pasada la ventana")


func _horizontal_speed() -> float:
	return Vector2(_player.velocity.x, _player.velocity.z).length()


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
