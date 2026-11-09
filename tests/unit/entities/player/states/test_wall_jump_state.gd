extends GutTest
## WallJumpState: coste (el primero gratis), dirección de salida y reinicio al tocar suelo.

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")

var _context: MovementContext
var _machine: StateMachine
var _wall_jump: WallJumpState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.wall_jump_reach = 0.75
	_context = ContextFixture.create(self, move)
	_wall_jump = WallJumpState.new()
	_machine = ContextFixture.start_machine(self, _context, [_wall_jump])


func test_first_is_free_and_chained_ones_cost() -> void:
	assert_eq(WallJumpState.cost(0, 0.5), 0.0)
	assert_eq(WallJumpState.cost(1, 0.5), 0.5)
	assert_eq(WallJumpState.cost(3, 0.5), 0.5)


func test_without_direction_it_kicks_straight_out() -> void:
	assert_eq(WallJumpState.kick_direction(Vector3.ZERO, Vector3.LEFT), Vector3.LEFT)


func test_along_the_wall_it_kicks_diagonally_away() -> void:
	var direction := WallJumpState.kick_direction(Vector3.FORWARD, Vector3.LEFT)
	assert_gt(direction.dot(Vector3.LEFT), 0.0, "se separa de la pared")
	assert_gt(direction.dot(Vector3.FORWARD), 0.0, "sigue hacia donde pedías")
	assert_almost_eq(direction.length(), 1.0, 1e-6)


func test_into_the_wall_it_bounces_away() -> void:
	var direction := WallJumpState.kick_direction(Vector3.RIGHT, Vector3.LEFT)
	assert_almost_eq(direction.dot(Vector3.LEFT), 1.0, 1e-6, "rebota recto hacia fuera")


func test_no_wall_without_a_sensor() -> void:
	assert_eq(_context.wall_normal(), Vector3.ZERO)
	assert_false(_wall_jump.can_enter())


func test_landing_resets_the_chain() -> void:
	_context.wall_jumps_chained = 2
	_machine.transition_to(_context.ground)
	assert_eq(_context.wall_jumps_chained, 0)
