extends GutTest
## El heraldo del Gremio: llega cada tantos enemigos derrotados, en el suelo cerca del jugador (a la
## distancia de los datos) y mirándolo, y lo avisa; si el anterior sigue esperando, se va. Al hablarle
## ofrece pactos distintos y se va.

const HeraldScene := preload("res://entities/interactables/herald/herald.tscn")

var _spawner: HeraldSpawner
var _world: Node3D
var _player: Node3D
var _data: HeraldData
var _arrived: Array[Vector3] = []
var _offers: Array = []


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)
	_add_floor()
	_player = Node3D.new()
	_world.add_child(_player)
	_data = (load("res://data/pacts/herald.tres") as HeraldData).duplicate()
	_data.every_kills = 5
	_spawner = HeraldSpawner.new()
	_spawner.data = _data
	_spawner.herald_scene = HeraldScene
	_spawner.player = _player
	_spawner.parent = _world
	_spawner.rng = RandomNumberGenerator.new()
	_spawner.rng.seed = 7
	add_child_autofree(_spawner)
	_arrived.clear()
	_offers.clear()
	EventBus.herald_arrived.connect(_on_arrived)
	EventBus.pact_offered.connect(_on_offered)
	await wait_physics_frames(2)


func after_each() -> void:
	EventBus.herald_arrived.disconnect(_on_arrived)
	EventBus.pact_offered.disconnect(_on_offered)


func test_arrives_after_enough_kills() -> void:
	_kill(_data.every_kills - 1)
	assert_null(_spawner.get_herald(), "aún no")
	_kill(1)
	var herald := _spawner.get_herald()
	assert_not_null(herald)
	assert_eq(_arrived.size(), 1, "lo avisa")
	var flat := Vector2(herald.global_position.x, herald.global_position.z)
	assert_between(flat.length(), _data.min_distance - 0.01, _data.max_distance + 0.01, "a su distancia")
	assert_almost_eq(herald.global_position.y, 0.0, 0.05, "en el suelo")
	var toward := (-herald.global_basis.z).dot(-herald.global_position.normalized())
	assert_gt(toward, 0.99, "mirando al jugador")


func test_only_one_waits() -> void:
	_kill(_data.every_kills)
	var first := _spawner.get_herald()
	_kill(_data.every_kills)
	assert_false(is_instance_valid(first), "el anterior se va")
	assert_not_null(_spawner.get_herald())
	assert_eq(_world.get_children().filter(func(child: Node) -> bool: return child is Herald).size(), 1)


func test_talking_offers_different_pacts_and_it_leaves() -> void:
	var herald := _spawner.summon()
	var pacts := herald.offer()
	assert_eq(pacts.size(), _data.choices)
	assert_eq(_offers.size(), 1)
	assert_ne(pacts[0], pacts[1])
	assert_true(herald.is_queued_for_deletion(), "se va")
	assert_null(_spawner.get_herald())


func test_avoids_obstacles() -> void:
	# Una pared que tapa media vuelta: el heraldo no aparece dentro.
	var wall := StaticBody3D.new()
	wall.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 6.0, 40.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(25.0, 3.0, 0.0)
	_world.add_child(wall)
	await wait_physics_frames(2)
	for _index: int in 10:
		var herald := _spawner.summon()
		assert_lt(herald.global_position.x, 5.0, "fuera de la pared")


func _kill(count: int) -> void:
	for _index: int in count:
		EventBus.enemy_died.emit(null)


func _add_floor() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	ground.position = Vector3(0.0, -0.5, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	ground.add_child(shape)
	_world.add_child(ground)


func _on_arrived(at: Vector3) -> void:
	_arrived.append(at)


func _on_offered(pacts: Array[PactData]) -> void:
	_offers.append(pacts)
