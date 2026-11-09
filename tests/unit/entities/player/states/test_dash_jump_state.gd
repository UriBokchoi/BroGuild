extends GutTest
## DashJumpState: solo justo después de un dash en el suelo, con stamina; salta recuperando la
## velocidad del dash y gasta la ventana.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")
const DASH_SPEED := 25.0
const WINDOW := 0.15

var _context: MovementContext
var _machine: StateMachine
var _dash_jump: DashJumpState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.dash_speed = DASH_SPEED
	move.dash_jump_window = WINDOW
	move.dash_jump_height = 2.0
	move.dash_jump_cost = 1.0
	_context = ContextFixture.create(self, move)
	_dash_jump = DashJumpState.new()
	_machine = ContextFixture.start_machine(self, _context, [_dash_jump])


func test_window_opens_only_right_after_a_ground_dash() -> void:
	assert_false(_context.is_dash_jump_open(), "sin dash, cerrada")
	_end_ground_dash(Vector3.RIGHT)
	assert_true(_context.is_dash_jump_open())
	_context.elapsed += WINDOW + 0.01
	assert_false(_context.is_dash_jump_open(), "pasada la ventana, cerrada")


func test_not_after_a_dash_in_the_air() -> void:
	_end_ground_dash(Vector3.RIGHT)
	_context.last_dash_in_air = true
	assert_false(_dash_jump.can_enter())


func test_needs_stamina() -> void:
	_end_ground_dash(Vector3.RIGHT)
	assert_true(_dash_jump.can_enter())
	_context.stamina.spend(3.0)
	assert_false(_dash_jump.can_enter())


func test_long_jump_with_the_dash_speed_that_spends_the_window() -> void:
	_end_ground_dash(Vector3.RIGHT)
	_machine.transition_to(_dash_jump)
	assert_eq(_context.body.velocity.x, DASH_SPEED, "recupera la velocidad del dash")
	assert_almost_eq(_context.body.velocity.y, 8.0, 1e-9, "√(2 × 16 m/s² × 2 m)")
	assert_eq(_context.stamina.get_charges(), 2.0)
	assert_false(_context.is_dash_jump_open(), "un dash, un dash-jump")


## Simula que acaba de terminar un dash hecho en el suelo en [param direction].
func _end_ground_dash(direction: Vector3) -> void:
	_context.elapsed = 1.0
	_context.last_dash_in_air = false
	_context.last_dash_direction = direction
	_context.dash_end_time = _context.elapsed
