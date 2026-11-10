extends GutTest
## FastFallState: solo en el aire, con Ctrl dos veces seguidas y con stamina; cae recto a su
## velocidad.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")
const FALL_SPEED := 45.0
const WINDOW := 0.3

var _context: MovementContext
var _machine: StateMachine
var _fast_fall: FastFallState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.fast_fall_speed = FALL_SPEED
	move.fast_fall_cost = 1.0
	move.fast_fall_double_tap_window = WINDOW
	_context = ContextFixture.create(self, move)
	_fast_fall = FastFallState.new()
	_fast_fall.trigger_action = &"slide"
	_machine = ContextFixture.start_machine(self, _context, [_fast_fall])


func test_needs_ctrl_twice() -> void:
	_context.record_press(&"slide")
	assert_false(_fast_fall.can_enter(), "un solo Ctrl no basta")
	_context.elapsed += WINDOW / 2.0
	_context.record_press(&"slide")
	assert_true(_fast_fall.can_enter(), "doble Ctrl en el aire")


func test_needs_stamina() -> void:
	_double_tap()
	_context.stamina.spend(3.0)
	assert_false(_fast_fall.can_enter())


func test_dives_straight_down_and_spends_a_charge() -> void:
	_context.body.velocity = Vector3(8.0, 3.0, 0.0)
	_machine.transition_to(_fast_fall)
	assert_eq(_context.body.velocity, Vector3.DOWN * FALL_SPEED)
	assert_eq(_context.stamina.get_charges(), 2.0)
	_machine.physics_update(1.0 / 60.0)
	assert_same(_machine.current, _fast_fall, "sigue cayendo hasta tocar suelo")


func _double_tap() -> void:
	_context.record_press(&"slide")
	_context.elapsed += WINDOW / 2.0
	_context.record_press(&"slide")
