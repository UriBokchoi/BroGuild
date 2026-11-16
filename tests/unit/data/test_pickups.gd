extends GutTest
## Recogibles de data/pickups: cada uno tiene identificador único, una escena que es un Pickup, una
## recompensa y cómo vuela hacia quien lo recoge.

const PICKUPS_DIR := "res://data/pickups"


func test_there_are_an_xp_gem_and_a_gold_coin() -> void:
	var ids: Array[StringName] = []
	for pickup: Resource in ResourceDir.load_all(PICKUPS_DIR, PickupData):
		ids.append((pickup as PickupData).id)
	assert_has(ids, &"xp_gem")
	assert_has(ids, &"gold_coin")


func test_each_pickup_is_complete() -> void:
	var ids: Array[StringName] = []
	for resource: Resource in ResourceDir.load_all(PICKUPS_DIR, PickupData):
		var pickup := resource as PickupData
		assert_does_not_have(ids, pickup.id, "id repetido: %s" % pickup.id)
		ids.append(pickup.id)
		assert_false(pickup.reward.is_empty(), "%s: sin recompensa" % pickup.id)
		assert_gt(pickup.collect_radius, 0.0, "%s: sin radio de recogida" % pickup.id)
		var node := pickup.scene.instantiate()
		assert_true(node is Pickup, "%s: su escena no es un Pickup" % pickup.id)
		node.free()
