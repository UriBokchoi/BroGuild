extends GutTest
## FastFallState: solo en el aire y con stamina; cae recto a su velocidad.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")
const FALL_SPEED := 45.0

var _context: MovementContext
var _machine: StateMachine
var _fast_fall: FastFallState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.fast_fall_speed = FALL_SPEED
	move.fast_fall_cost = 1.0
	_context = ContextFixture.create(self, move)
	_fast_fall = FastFallState.new()
	_machine = ContextFixture.start_machine(self, _context, [_fast_fall])


func test_in_the_air_with_stamina() -> void:
	assert_true(_fast_fall.can_enter(), "el cuerpo de prueba siempre está en el aire")
	_context.stamina.spend(3.0)
	assert_false(_fast_fall.can_enter(), "sin cargas no")


func test_dives_straight_down_and_spends_a_charge() -> void:
	_context.body.velocity = Vector3(8.0, 3.0, 0.0)
	_machine.transition_to(_fast_fall)
	assert_eq(_context.body.velocity, Vector3.DOWN * FALL_SPEED)
	assert_eq(_context.stamina.get_charges(), 2.0)
	_machine.physics_update(1.0 / 60.0)
	assert_same(_machine.current, _fast_fall, "sigue cayendo hasta tocar suelo")
