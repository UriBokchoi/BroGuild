extends GutTest
## Invocador de práctica: al interactuar saca su anillo de enemigos alrededor de quien lo usa, y su
## cartel dice qué enemigo invoca.

const SummonerScene := preload("res://entities/interactables/summoner/summoner.tscn")

var _swarm: EnemySwarm
var _summoner: Summoner


func before_each() -> void:
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)
	_summoner = SummonerScene.instantiate() as Summoner
	_summoner.swarm = _swarm
	add_child_autofree(_summoner)


func test_interacting_summons_a_ring_around_the_user() -> void:
	var user := Node3D.new()
	user.position = Vector3(3.0, 0.0, 4.0)
	add_child_autofree(user)
	_summoner.interactable.interact(user)
	assert_eq(_swarm.active_count(), _summoner.count)
	for enemy: Enemy in _swarm.get_active():
		var distance := Vector2(enemy.global_position.x - 3.0, enemy.global_position.z - 4.0).length()
		assert_almost_eq(distance, _summoner.ring_radius, 0.01)


func test_its_label_names_the_enemy() -> void:
	assert_eq(_summoner.label.text, String(_summoner.enemy.name_key))


func test_an_elite_summoner_summons_elites_and_says_so() -> void:
	var elite_summoner := SummonerScene.instantiate() as Summoner
	elite_summoner.swarm = _swarm
	elite_summoner.elite = load("res://data/enemies/elite.tres") as EliteData
	add_child_autofree(elite_summoner)
	elite_summoner.summon(Vector3.ZERO)
	for enemy: Enemy in _swarm.get_active():
		assert_true(enemy.is_elite())
	assert_ne(elite_summoner.label.text, String(elite_summoner.enemy.name_key), "su cartel dice que son élites")
