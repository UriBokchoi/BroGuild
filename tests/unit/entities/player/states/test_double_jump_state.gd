extends GutTest
## DoubleJumpState: en el aire, sin coyote time, con saltos en el aire y stamina; tocar suelo
## devuelve los saltos.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")

var _context: MovementContext
var _machine: StateMachine
var _double_jump: DoubleJumpState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.air_jumps = 1
	move.air_jump_height = 2.0
	move.air_jump_cost = 1.0
	_context = ContextFixture.create(self, move)
	_double_jump = DoubleJumpState.new()
	_machine = ContextFixture.start_machine(self, _context, [_double_jump])


func test_can_jump_in_the_air_with_a_jump_left() -> void:
	assert_true(_double_jump.can_enter())


func test_not_during_coyote_time() -> void:
	_context.coyote_left = 0.05
	assert_false(_double_jump.can_enter(), "con coyote time el salto es el normal")


func test_not_without_air_jumps_left() -> void:
	_context.air_jumps_used = 1
	assert_false(_double_jump.can_enter())


func test_not_without_stamina() -> void:
	_context.stamina.spend(3.0)
	assert_false(_double_jump.can_enter())


func test_spends_a_jump_and_a_charge_and_jumps_its_height() -> void:
	_machine.transition_to(_double_jump)
	assert_almost_eq(_context.body.velocity.y, 8.0, 1e-9, "√(2 × 16 m/s² × 2 m)")
	assert_eq(_context.air_jumps_used, 1)
	assert_eq(_context.stamina.get_charges(), 2.0)


func test_more_air_jumps_allow_a_triple_jump() -> void:
	_context.move.air_jumps = 2
	_context.air_jumps_used = 1
	assert_true(_double_jump.can_enter())


func test_landing_gives_the_air_jumps_back() -> void:
	_context.air_jumps_used = 1
	_machine.transition_to(_context.ground)
	assert_eq(_context.air_jumps_used, 0)
