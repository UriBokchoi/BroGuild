extends GutTest
## DownDashState (picado): solo en el aire, sin dirección y poco después de un dash hecho en el
## aire; gasta su propia carga y va hacia abajo.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")
const DIVE_SPEED := 30.0

var _context: MovementContext
var _machine: StateMachine
var _dash: DashState
var _dive: DownDashState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.dash_speed = 20.0
	move.dash_duration = 0.2
	move.dash_cost = 1.0
	move.down_dash_speed = DIVE_SPEED
	move.down_dash_duration = 0.2
	move.down_dash_window = 0.3
	move.down_dash_cost = 1.0
	_context = ContextFixture.create(self, move)
	_dash = DashState.new()
	_dive = DownDashState.new()
	_machine = ContextFixture.start_machine(self, _context, [_dash, _dive])


func test_second_shift_in_the_air_without_direction_dives() -> void:
	_machine.transition_to(_dash)
	_context.elapsed = 0.1
	assert_true(_dive.can_enter())
	_machine.transition_to(_dive)
	assert_eq(_context.body.velocity, Vector3.DOWN * DIVE_SPEED)
	assert_eq(_context.stamina.get_charges(), 1.0, "dash + picado = 2 cargas")


func test_not_with_a_direction() -> void:
	_machine.transition_to(_dash)
	_context.wish_direction = Vector3.RIGHT
	assert_false(_dive.can_enter())


func test_not_after_the_window() -> void:
	_machine.transition_to(_dash)
	_context.elapsed = 0.5
	assert_false(_dive.can_enter())


func test_not_without_a_dash_in_the_air_before() -> void:
	assert_false(_dive.can_enter(), "sin dash previo")
	_context.last_dash_time = 0.0
	_context.last_dash_in_air = false
	assert_false(_dive.can_enter(), "el dash fue en el suelo")


func test_not_without_stamina() -> void:
	_machine.transition_to(_dash)
	_context.stamina.spend(2.0)
	assert_false(_dive.can_enter())
