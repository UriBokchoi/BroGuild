extends GutTest
## Llave del jefe: al cogerla avisa una sola vez, deja de poder usarse y desaparece.

const KeyScene := preload("res://entities/interactables/boss_key/boss_key.tscn")

var _taken: int = 0


func before_each() -> void:
	_taken = 0
	EventBus.boss_key_collected.connect(_on_taken)


func after_each() -> void:
	EventBus.boss_key_collected.disconnect(_on_taken)


func test_taking_it_counts_once_and_it_vanishes() -> void:
	var key := KeyScene.instantiate() as BossKey
	add_child_autofree(key)
	key.interactable.interact(key)
	key.interactable.interact(key)
	key.take()
	assert_eq(_taken, 1)
	assert_true(key.is_taken())
	assert_false(key.interactable.enabled)
	await wait_seconds(key.pop_time + 0.1)
	assert_false(is_instance_valid(key), "desaparece")


func _on_taken() -> void:
	_taken += 1
