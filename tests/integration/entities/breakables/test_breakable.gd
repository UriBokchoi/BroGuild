extends GutTest
## Rompible con física real: lo rompe el cuerpo del jugador al tocarlo (no un enemigo), avisa una
## sola vez con su botín y su posición, y desaparece.

const SkullScene := preload("res://entities/breakables/skull/skull.tscn")

var _skull: Breakable
var _broken: Array[Vector3] = []


func before_each() -> void:
	_broken.clear()
	EventBus.breakable_broken.connect(_on_broken)
	_skull = SkullScene.instantiate() as Breakable
	_skull.position = Vector3(3.0, 0.0, 0.0)
	add_child_autofree(_skull)


func after_each() -> void:
	EventBus.breakable_broken.disconnect(_on_broken)


func test_the_player_breaks_it_by_touching_it() -> void:
	_add_body(PhysicsLayers.PLAYER, _skull.position)
	await wait_physics_frames(3)
	assert_eq(_broken.size(), 1)
	assert_eq(_broken[0], _skull.global_position)
	assert_true(_skull.is_broken())


func test_an_enemy_does_not_break_it() -> void:
	_add_body(PhysicsLayers.ENEMY, _skull.position)
	await wait_physics_frames(3)
	assert_eq(_broken.size(), 0)


func test_it_breaks_only_once_and_goes_away() -> void:
	_skull.break_open()
	_skull.break_open()
	assert_eq(_broken.size(), 1)
	await wait_seconds(_skull.pop_time + 0.1)
	assert_false(is_instance_valid(_skull), "desaparece tras el estallido")


func _add_body(layer: int, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.mask(layer)
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	body.add_child(shape)
	body.position = at + Vector3.UP * 0.5
	add_child_autofree(body)


func _on_broken(data: BreakableData, at: Vector3) -> void:
	assert_same(data, _skull.data)
	_broken.append(at)
