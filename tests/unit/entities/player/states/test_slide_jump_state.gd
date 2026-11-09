extends GutTest
## SlideJumpState: solo durante el slide (lo que interrumpe) y sin perder el impulso horizontal.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")

var _context: MovementContext
var _machine: StateMachine
var _slide: SlideState
var _slide_jump: SlideJumpState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	_context = ContextFixture.create(self, move)
	_slide = SlideState.new()
	_slide_jump = SlideJumpState.new()
	_slide_jump.interrupts.append(_slide)
	_machine = ContextFixture.start_machine(self, _context, [_slide, _slide_jump])


func test_only_while_sliding() -> void:
	assert_false(_slide_jump.can_enter(), "en Aire no")
	_machine.transition_to(_slide)
	assert_true(_slide_jump.can_enter())


func test_jumps_keeping_the_slide_momentum() -> void:
	_machine.transition_to(_slide)
	_context.body.velocity = Vector3(15.0, -2.0, 0.0)
	_machine.transition_to(_slide_jump)
	assert_eq(_context.body.velocity.x, 15.0, "conserva el impulso")
	assert_almost_eq(_context.body.velocity.y, _context.move.jump_velocity(), 1e-9)
