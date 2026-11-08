extends GutTest
## JumpState: cuándo se puede saltar (suelo o coyote time) y qué impulso da.

var _body: CharacterBody3D
var _context: MovementContext
var _jump: JumpState


func before_each() -> void:
	var move := MovementData.new()
	move.jump_height = 2.0
	move.jump_time_to_apex = 0.5
	_body = autofree(CharacterBody3D.new())
	_context = MovementContext.new()
	_context.body = _body
	_context.move = move
	_jump = autofree(JumpState.new())
	_jump.setup(_context)


func test_cannot_jump_in_the_air_without_coyote_time() -> void:
	assert_false(_jump.can_enter(), "un cuerpo fuera del árbol nunca está en el suelo")


func test_can_jump_during_coyote_time() -> void:
	_context.coyote_left = 0.05
	assert_true(_jump.can_enter())


func test_jumping_gives_the_jump_velocity_and_spends_coyote_time() -> void:
	_context.coyote_left = 0.05
	_jump.enter(null)
	assert_almost_eq(_body.velocity.y, 8.0, 1e-9, "2 × 2 m / 0,5 s")
	assert_eq(_context.coyote_left, 0.0)
