extends GutTest
## FireTrail con física real: en el slide deja manchas de fuego cada tantos metros; lo que pisa
## alguna se quema cada poco, una sola vez por quemadura aunque pise varias; las manchas se apagan al
## acabar su vida. Sin daño (sin la runa) no deja nada.

const Target := preload("res://tests/integration/entities/player/synergy/synergy_target.gd")
const FakeState := preload("res://tests/unit/core/state_machine/fake_state.gd")
const PATCH_MESH := preload("res://entities/player/synergy/fire_patch.tres")

var _machine: StateMachine
var _idle: FakeState
var _slide: FakeState
var _body: Node3D


func before_each() -> void:
	_machine = StateMachine.new()
	add_child_autofree(_machine)
	_idle = FakeState.new()
	_slide = FakeState.new()
	_machine.add_child(_idle)
	_machine.add_child(_slide)
	_machine.initial_state = _idle
	_body = Node3D.new()
	add_child_autofree(_body)
	_machine.start(null)


func test_sliding_drops_patches_every_few_metres() -> void:
	var trail := _trail(10.0)
	_machine.transition_to(_slide)
	assert_true(trail.is_trailing())
	assert_eq(trail.active_patches(), 1, "una al empezar")
	for step: int in 6:
		_body.position.x += trail.spacing * 0.5
		await wait_physics_frames(1)
	assert_eq(trail.active_patches(), 4, "una cada %s m" % trail.spacing)
	_machine.transition_to(_idle)
	assert_false(trail.is_trailing())
	_body.position.x += trail.spacing * 3.0
	await wait_physics_frames(2)
	assert_eq(trail.active_patches(), 4, "fuera del slide no deja más")


func test_burns_what_stands_on_it_once_per_tick() -> void:
	var trail := _trail(10.0)
	var standing := Target.enemy(self, Vector3(0.3, 0.0, 0.0))
	var away := Target.enemy(self, Vector3(trail.radius + 3.0, 0.0, 0.0))
	await wait_physics_frames(2)
	_machine.transition_to(_slide)
	# Una segunda mancha encima: pisa dos y solo se quema una vez por quemadura.
	_body.position.x = trail.spacing
	await wait_seconds(trail.burn_interval * 2.0 + 0.1)
	assert_almost_eq(standing.get_current(), 70.0, 0.01, "tres quemaduras (al empezar y dos más)")
	assert_eq(away.get_current(), 100.0, "fuera del fuego")


func test_patches_go_out_after_their_lifetime() -> void:
	var trail := _trail(10.0)
	trail.lifetime = 0.3
	_machine.transition_to(_slide)
	_machine.transition_to(_idle)
	assert_eq(trail.active_patches(), 1)
	await wait_seconds(0.45)
	assert_eq(trail.active_patches(), 0)
	assert_false(trail.is_physics_processing(), "sin manchas ni slide, se para")


func test_without_damage_it_leaves_nothing() -> void:
	var trail := _trail(0.0)
	_machine.transition_to(_slide)
	assert_false(trail.is_trailing())
	assert_eq(trail.active_patches(), 0)


func test_area_grows_the_patches() -> void:
	var trail := _trail(10.0, 200.0)
	_machine.transition_to(_slide)
	var patch := trail.get_child(0) as MeshInstance3D
	assert_almost_eq(patch.scale.x, trail.radius * 2.0, 0.001)


## Un FireTrail que deja rastro en [member _slide], con [param damage] por quemadura y [param area] %
## de área.
func _trail(damage: float, area: float = 100.0) -> FireTrail:
	var synergy := MovementSynergyData.new()
	synergy.fire_trail_damage = damage
	var trail := FireTrail.new()
	trail.stats = Target.stats(self, synergy, area)
	trail.body = _body
	trail.machine = _machine
	trail.trail_state = _slide
	trail.hit_mask = PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX)
	trail.patch_mesh = PATCH_MESH
	add_child_autofree(trail)
	return trail
