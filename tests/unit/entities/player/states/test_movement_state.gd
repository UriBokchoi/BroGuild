extends GutTest
## Utilidades comunes de los estados de movimiento (probadas a través de AirState): gravedad
## con tope de caída y control aéreo que conserva el impulso.

const TICK := 1.0 / 60.0
const RUN_SPEED := 9.0
const AIR_ACCELERATION := 30.0

var _body: CharacterBody3D
var _context: MovementContext
var _state: AirState


func before_each() -> void:
	var move := MovementData.new()
	move.jump_height = 2.0
	move.jump_time_to_apex = 0.5
	move.max_fall_speed = 10.0
	move.run_speed = RUN_SPEED
	move.air_acceleration = AIR_ACCELERATION
	_body = autofree(CharacterBody3D.new())
	_context = MovementContext.new()
	_context.body = _body
	_context.move = move
	_state = autofree(AirState.new())
	_state.setup(_context)


func test_gravity_accelerates_the_fall() -> void:
	_state.apply_gravity(TICK)
	assert_almost_eq(_body.velocity.y, -16.0 * TICK, 1e-6)


func test_fall_speed_is_capped() -> void:
	for _tick: int in 120:
		_state.apply_gravity(TICK)
	assert_almost_eq(_body.velocity.y, -10.0, 1e-6)


func test_air_control_accelerates_towards_the_wish_direction() -> void:
	_context.wish_direction = Vector3.RIGHT
	_state.apply_air_control(TICK)
	assert_almost_eq(_body.velocity.x, AIR_ACCELERATION * TICK, 1e-6)


func test_air_control_keeps_momentum_above_run_speed() -> void:
	_body.velocity = Vector3(15.0, 0.0, 0.0)
	_context.wish_direction = Vector3.RIGHT
	_state.apply_air_control(TICK)
	assert_almost_eq(_state.horizontal_speed(), 15.0, 1e-6, "no frena el impulso del dash")


func test_pressing_backwards_in_the_air_brakes() -> void:
	_body.velocity = Vector3(15.0, 0.0, 0.0)
	_context.wish_direction = Vector3.LEFT
	_state.apply_air_control(TICK)
	assert_almost_eq(_body.velocity.x, 15.0 - AIR_ACCELERATION * TICK, 1e-6)


func test_without_input_only_air_deceleration_slows_down() -> void:
	_body.velocity = Vector3(15.0, 0.0, 0.0)
	_state.apply_air_control(TICK)
	assert_almost_eq(_body.velocity.x, 15.0, 1e-6, "sin frenada en el aire, se conserva")
	_context.move.air_deceleration = 6.0
	_state.apply_air_control(TICK)
	assert_almost_eq(_body.velocity.x, 15.0 - 6.0 * TICK, 1e-6)
