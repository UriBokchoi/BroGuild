extends GutTest
## Utilidades comunes de los estados de movimiento (probadas a través de AirState).

const TICK := 1.0 / 60.0

var _body: CharacterBody3D
var _state: AirState


func before_each() -> void:
	var move := MovementData.new()
	move.jump_height = 2.0
	move.jump_time_to_apex = 0.5
	move.max_fall_speed = 10.0
	_body = autofree(CharacterBody3D.new())
	var context := MovementContext.new()
	context.body = _body
	context.move = move
	_state = autofree(AirState.new())
	_state.setup(context)


func test_gravity_accelerates_the_fall() -> void:
	_state.apply_gravity(TICK)
	assert_almost_eq(_body.velocity.y, -16.0 * TICK, 1e-6)


func test_fall_speed_is_capped() -> void:
	for _tick: int in 120:
		_state.apply_gravity(TICK)
	assert_almost_eq(_body.velocity.y, -10.0, 1e-6)
