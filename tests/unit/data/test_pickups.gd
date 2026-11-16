extends GutTest
## Recogibles de data/pickups: cada uno tiene identificador único, una escena que es un Pickup, una
## recompensa y cómo vuela hacia quien lo recoge; los que se juntan, en grupos, y sus niveles, de
## menor a mayor valor.

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


func test_merging_pickups_need_a_group_and_tiers_go_up() -> void:
	for resource: Resource in ResourceDir.load_all(PICKUPS_DIR, PickupData):
		var pickup := resource as PickupData
		if pickup.merge_radius > 0.0:
			assert_gte(pickup.merge_count, 2, "%s: se junta con al menos otro" % pickup.id)
		var previous := -1.0
		for tier: PickupTier in pickup.tiers:
			assert_gt(tier.min_amount, previous, "%s: niveles de menor a mayor valor" % pickup.id)
			assert_gt(tier.scale, 0.0, "%s: nivel sin tamaño" % pickup.id)
			previous = tier.min_amount
		if not pickup.tiers.is_empty():
			assert_eq(pickup.tiers[0].min_amount, 0.0, "%s: el primer nivel sirve para todo valor" % pickup.id)


func test_tier_for_picks_the_highest_reached() -> void:
	var data := PickupData.new()
	for min_amount: float in [0.0, 5.0, 25.0]:
		var tier := PickupTier.new()
		tier.min_amount = min_amount
		data.tiers.append(tier)
	assert_eq(data.tier_for(1.0).min_amount, 0.0)
	assert_eq(data.tier_for(5.0).min_amount, 5.0)
	assert_eq(data.tier_for(24.0).min_amount, 5.0)
	assert_eq(data.tier_for(400.0).min_amount, 25.0)
	assert_null(PickupData.new().tier_for(3.0), "sin niveles")
