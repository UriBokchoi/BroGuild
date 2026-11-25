extends GutTest
## Polvo de los pasos: cada paso (a rapidez suficiente) suelta un soplo a los pies, un pie a cada
## lado; andando muy despacio, nada. El jugador lo lleva enganchado a su balanceo.

const PlayerScene := preload("res://entities/player/player.tscn")
const PUFF := preload("res://vfx/particles/step_dust.tscn")

var _bob: BodyBob
var _walker: CharacterBody3D
var _dust: StepDust


func before_each() -> void:
	# El balanceo no entra en el árbol: aquí solo hace falta su señal.
	_bob = BodyBob.new()
	_walker = CharacterBody3D.new()
	add_child_autofree(_walker)
	_walker.velocity = Vector3(0.0, 0.0, -5.0)
	_dust = StepDust.new()
	_dust.bob = _bob
	_dust.walker = _walker
	_dust.dust = PUFF
	add_child_autofree(_dust)


func after_each() -> void:
	_bob.free()


func test_each_step_puffs_on_alternate_feet() -> void:
	_bob.stepped.emit(1.0)
	var first := _active().global_position
	_bob.stepped.emit(1.0)
	var second := _active().global_position
	assert_eq(_dust.get_steps(), 2)
	assert_almost_eq(first.x, _dust.foot_offset, 0.001, "un pie a un lado de la marcha")
	assert_almost_eq(second.x, -_dust.foot_offset, 0.001, "y el otro al otro")


func test_walking_slowly_raises_no_dust() -> void:
	_bob.stepped.emit(_dust.min_ratio * 0.5)
	assert_eq(_dust.get_steps(), 0)


func test_the_player_has_it_on_its_steps() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var dust := player.get_node(^"StepDust") as StepDust
	assert_same(dust.bob, player.get_node(^"BodyBob"))
	assert_same(dust.walker, player)


## El último soplo lanzado.
func _active() -> GPUParticles3D:
	var emitters := _dust.get_children()
	var index := (_dust.get_steps() - 1) % emitters.size()
	return emitters[index] as GPUParticles3D
