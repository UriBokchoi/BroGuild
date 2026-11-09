extends GutTest
## SlideState: tirón de la pendiente y qué pasa sin suelo (el resto, con física real, en los tests
## de integración del jugador).

const ContextFixture := preload("res://tests/unit/entities/player/states/movement_context_fixture.gd")
const SLOPE := deg_to_rad(15.0)
const SLIDE_GRAVITY := 30.0

var _context: MovementContext
var _machine: StateMachine
var _slide: SlideState


func before_each() -> void:
	var move := ContextFixture.movement_with_gravity()
	move.slide_min_speed = 6.0
	move.slide_max_speed = 22.0
	move.coyote_time = 0.1
	_context = ContextFixture.create(self, move)
	_slide = SlideState.new()
	_machine = ContextFixture.start_machine(self, _context, [_slide])


func test_flat_ground_does_not_pull() -> void:
	assert_eq(SlideState.slope_pull(Vector3.UP, SLIDE_GRAVITY), Vector3.ZERO)


func test_slope_pulls_downhill_in_proportion_to_its_angle() -> void:
	# Pendiente que baja hacia −Z.
	var normal := Vector3(0.0, cos(SLOPE), -sin(SLOPE))
	var pull := SlideState.slope_pull(normal, SLIDE_GRAVITY)
	assert_almost_eq(pull.length(), SLIDE_GRAVITY * sin(SLOPE), 1e-6)
	assert_lt(pull.z, 0.0, "hacia abajo de la pendiente")
	assert_lt(pull.y, 0.0)


func test_steering_turns_towards_the_wish_at_most_max_turn_keeping_speed() -> void:
	var velocity := Vector3(0.0, -1.0, -10.0)
	var turned := SlideState.steer(velocity, Vector3.RIGHT, deg_to_rad(10.0))
	assert_almost_eq(Vector2(turned.x, turned.z).length(), 10.0, 1e-6, "no pierde velocidad")
	assert_almost_eq(Vector2(0.0, -1.0).angle_to(Vector2(turned.x, turned.z)), deg_to_rad(10.0), 1e-6, "gira 10° hacia la derecha")
	assert_eq(turned.y, -1.0, "la parte vertical no cambia")


func test_steering_reaches_the_wish_when_it_is_close() -> void:
	var turned := SlideState.steer(Vector3(0.0, 0.0, -10.0), Vector3(0.1, 0.0, -1.0), deg_to_rad(90.0))
	assert_almost_eq(Vector2(turned.x, turned.z).normalized().dot(Vector2(0.1, -1.0).normalized()), 1.0, 1e-6)


func test_without_wish_it_does_not_turn() -> void:
	var velocity := Vector3(3.0, 0.0, -4.0)
	assert_eq(SlideState.steer(velocity, Vector3.ZERO, 1.0), velocity)


func test_cannot_slide_in_the_air() -> void:
	_context.body.velocity = Vector3(10.0, 0.0, 0.0)
	assert_false(_slide.can_enter(), "un cuerpo fuera del árbol nunca está en el suelo")


func test_leaving_the_ground_goes_to_the_air_with_coyote_time() -> void:
	_machine.transition_to(_slide)
	_machine.physics_update(1.0 / 60.0)
	assert_same(_machine.current, _context.air)
	assert_eq(_context.coyote_left, 0.1)
