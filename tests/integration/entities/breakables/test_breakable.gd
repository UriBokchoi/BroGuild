extends GutTest
## Rompible: se rompe al usarlo con «interactuar» (no al tocarlo), avisa una sola vez con su botín y
## su posición, deja de ofrecerse y desaparece.

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


func test_it_breaks_when_used() -> void:
	assert_eq(_skull.interactable.prompt_key, &"BREAK_SKULL")
	_skull.interactable.interact(_user())
	assert_eq(_broken.size(), 1)
	assert_eq(_broken[0], _skull.global_position)
	assert_true(_skull.is_broken())
	assert_false(_skull.interactable.enabled, "ya no se ofrece")


func test_touching_it_does_not_break_it() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.mask(PhysicsLayers.PLAYER)
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	body.add_child(shape)
	body.position = _skull.position + Vector3.UP * 0.5
	add_child_autofree(body)
	await wait_physics_frames(3)
	assert_eq(_broken.size(), 0)


func test_it_breaks_only_once_and_goes_away() -> void:
	_skull.break_open()
	_skull.break_open()
	assert_eq(_broken.size(), 1)
	await wait_seconds(_skull.pop_time + 0.1)
	assert_false(is_instance_valid(_skull), "desaparece tras el estallido")


## Quien interactúa (basta un nodo).
func _user() -> Node3D:
	var node := Node3D.new()
	add_child_autofree(node)
	return node


func _on_broken(data: BreakableData, at: Vector3) -> void:
	assert_same(data, _skull.data)
	_broken.append(at)
