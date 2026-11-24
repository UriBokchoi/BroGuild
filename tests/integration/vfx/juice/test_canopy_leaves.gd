extends GutTest
## Hojas de las copas: al meter el cuerpo en la copa de un árbol, caen hojas (una vez al entrar, y no
## otra vez del mismo árbol hasta pasado un rato); por debajo de la copa o lejos, nada. Los árboles de
## fuera de las paredes no se miran.

const Scene := preload("res://vfx/juice/canopy_leaves/canopy_leaves.tscn")

var _leaves: CanopyLeaves
var _target: Node3D
var _round := {"at": Vector2(4.0, 0.0), "scale": 1.0, "yaw": 0.0, "round": true, "color": Color.GREEN, "collides": true}


func before_each() -> void:
	_target = Node3D.new()
	add_child_autofree(_target)
	_leaves = Scene.instantiate() as CanopyLeaves
	_leaves.target = _target
	_leaves.check_interval = 0.02
	_leaves.tree_cooldown = 0.5
	add_child_autofree(_leaves)
	var far := {"at": Vector2(120.0, 0.0), "scale": 1.0, "yaw": 0.0, "round": true, "color": Color.RED, "collides": false}
	_leaves.set_trees([_round, far] as Array[Dictionary])


func test_only_the_trees_inside_the_walls_count() -> void:
	assert_eq(_leaves.tree_count(), 1)


func test_entering_a_canopy_drops_leaves_once() -> void:
	var canopy := ForestBuilder.canopy(_round)
	_target.position = Vector3(4.0, 0.0, 0.0)
	await wait_seconds(0.1)
	assert_eq(_leaves.get_drops(), 0, "debajo de la copa, nada")
	_target.position = Vector3(4.0, (canopy.y + canopy.z) / 2.0 - _leaves.body_height, 0.0)
	await wait_seconds(0.1)
	assert_eq(_leaves.get_drops(), 1, "al entrar, hojas")
	await wait_seconds(0.1)
	assert_eq(_leaves.get_drops(), 1, "quedarse dentro no suelta más")


func test_the_same_tree_waits_before_dropping_again() -> void:
	var canopy := ForestBuilder.canopy(_round)
	var inside := Vector3(4.0, (canopy.y + canopy.z) / 2.0 - _leaves.body_height, 0.0)
	_target.position = inside
	await wait_seconds(0.1)
	_target.position = Vector3(4.0, 0.0, 0.0)
	await wait_seconds(0.1)
	_target.position = inside
	await wait_seconds(0.1)
	assert_eq(_leaves.get_drops(), 1, "aún no")
	_target.position = Vector3(4.0, 0.0, 0.0)
	await wait_seconds(_leaves.tree_cooldown)
	_target.position = inside
	await wait_seconds(0.1)
	assert_eq(_leaves.get_drops(), 2, "pasado el rato, otra vez")


func test_a_pine_canopy_starts_above_the_trunk() -> void:
	var pine := _round.duplicate()
	pine["round"] = false
	var canopy := ForestBuilder.canopy(pine)
	assert_gt(canopy.y, 1.5, "empieza por encima de la cabeza")
	assert_gt(canopy.z, canopy.y)
	assert_gt(canopy.x, 0.5)
