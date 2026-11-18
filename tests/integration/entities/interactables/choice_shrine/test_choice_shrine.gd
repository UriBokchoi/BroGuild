extends GutTest
## Círculo de setas: al usarlo ofrece tres objetos distintos para elegir y se apaga; no se puede
## usar dos veces.

const RingScene := preload("res://entities/interactables/choice_shrine/mushroom_ring.tscn")

var _offers: Array = []


func before_each() -> void:
	_offers.clear()
	EventBus.item_choice_offered.connect(_on_offered)


func after_each() -> void:
	EventBus.item_choice_offered.disconnect(_on_offered)


func test_offers_three_different_items_once() -> void:
	var ring := RingScene.instantiate() as ChoiceShrine
	ring.rng = RandomNumberGenerator.new()
	ring.rng.seed = 2
	add_child_autofree(ring)
	assert_true(ring.offer())
	assert_eq(_offers.size(), 1)
	var items: Array[PassiveItemData] = _offers[0]
	assert_eq(items.size(), ring.choices)
	assert_ne(items[0], items[1])
	assert_true(ring.is_used())
	assert_false(ring.interactable.enabled)
	assert_false(ring.glow.visible, "se apaga")
	assert_false(ring.offer(), "una sola vez")
	assert_eq(_offers.size(), 1)


func _on_offered(items: Array[PassiveItemData]) -> void:
	_offers.append(items)
