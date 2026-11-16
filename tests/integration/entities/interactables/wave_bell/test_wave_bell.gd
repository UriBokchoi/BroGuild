extends GutTest
## Campana de oleadas: al interactuar arranca o para su director, y su aviso dice qué hará.

const BellScene := preload("res://entities/interactables/wave_bell/wave_bell.tscn")

var _director: WaveDirector
var _bell: WaveBell


func before_each() -> void:
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	_director = WaveDirector.new()
	_director.data = WaveData.new()
	_director.swarm = swarm
	add_child_autofree(_director)
	_bell = BellScene.instantiate() as WaveBell
	add_child_autofree(_bell)
	_bell.use_director(_director)


func test_interacting_toggles_the_waves() -> void:
	_bell.interactable.interact(_bell)
	assert_true(_director.is_running())
	_bell.interactable.interact(_bell)
	assert_false(_director.is_running())


func test_prompt_says_what_it_will_do() -> void:
	assert_eq(_bell.interactable.prompt_key, &"INTERACT_WAVES_START")
	_director.start()
	assert_eq(_bell.interactable.prompt_key, &"INTERACT_WAVES_STOP")
	_director.stop()
	assert_eq(_bell.interactable.prompt_key, &"INTERACT_WAVES_START")
