extends GutTest
## DashState: gasta stamina, va en la dirección pedida (o hacia la cámara) a dash_speed y sin
## gravedad, y al terminar deja la velocidad horizontal en dash_exit_speed como mucho.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")
const TICK := 1.0 / 60.0
const DASH_SPEED := 30.0
const EXIT_SPEED := 10.0

var _context: MovementContext
var _machine: StateMachine
var _dash: DashState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.dash_speed = DASH_SPEED
	move.dash_duration = 0.2
	move.dash_exit_speed = EXIT_SPEED
	move.dash_cost = 1.0
	_context = ContextFixture.create(self, move)
	_dash = DashState.new()
	_machine = ContextFixture.start_machine(self, _context, [_dash])


func test_needs_stamina() -> void:
	assert_true(_dash.can_enter())
	_context.stamina.spend(3.0)
	assert_false(_dash.can_enter(), "sin cargas no hay dash")


func test_dashes_where_you_ask_and_spends_a_charge() -> void:
	_context.wish_direction = Vector3.RIGHT
	_machine.transition_to(_dash)
	assert_eq(_context.body.velocity, Vector3.RIGHT * DASH_SPEED)
	assert_eq(_context.stamina.get_charges(), 2.0)


func test_without_direction_dashes_where_the_camera_looks() -> void:
	_context.view_forward = Vector3.BACK
	_machine.transition_to(_dash)
	assert_eq(_context.body.velocity, Vector3.BACK * DASH_SPEED)


func test_flies_straight_while_it_lasts() -> void:
	_context.wish_direction = Vector3.RIGHT
	_machine.transition_to(_dash)
	_machine.physics_update(TICK)
	assert_same(_machine.current, _dash)
	assert_eq(_context.body.velocity.y, 0.0, "sin gravedad durante el dash")
	assert_almost_eq(_dash.time_left(), 0.2 - TICK, 1e-6)


func test_remembers_when_and_where_it_started_for_the_dive() -> void:
	_context.elapsed = 4.0
	_machine.transition_to(_dash)
	assert_eq(_context.last_dash_time, 4.0)
	assert_true(_context.last_dash_in_air)


func test_ends_after_its_duration_keeping_at_most_the_exit_speed() -> void:
	_context.wish_direction = Vector3.RIGHT
	_machine.transition_to(_dash)
	for _tick: int in 12:
		_machine.physics_update(TICK)
	_machine.physics_update(TICK)
	assert_same(_machine.current, _context.air, "en el aire vuelve a Aire")
	assert_almost_eq(_context.body.velocity.x, EXIT_SPEED, 1e-6)
