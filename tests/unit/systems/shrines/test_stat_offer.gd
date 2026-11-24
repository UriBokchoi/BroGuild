extends GutTest
## StatOffer: tira tantas ofertas como se piden, con stats distintas y una rareza de la tabla cada
## una; su modificador lleva la fuerza de su rareza.

const SHRINE := preload("res://data/shrines/dumbbell.tres")
const RARE := preload("res://data/rarities/rare.tres")


func test_distinct_stats_with_a_rarity_each() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for round_index: int in 20:
		var offers := StatOffer.roll(SHRINE.stats, 3, SHRINE.rarities, 0.0, rng)
		assert_eq(offers.size(), 3)
		var names := {}
		for offer: StatOffer in offers:
			assert_has(SHRINE.rarities.entries, offer.rarity)
			names[offer.stat.stat] = true
		assert_eq(names.size(), 3, "sin repetir stat")


func test_the_rarity_sets_the_strength() -> void:
	var offer := StatOffer.new()
	offer.stat = SHRINE.stats[0]
	offer.rarity = RARE
	var rare_value := offer.modifier().value
	offer.rarity = preload("res://data/rarities/mythic.tres")
	assert_gt(offer.modifier().value, rare_value, "más rara, más fuerte")


func test_never_more_than_the_pool() -> void:
	var pool: Array[UpgradeStat] = [SHRINE.stats[0]]
	var offers := StatOffer.roll(pool, 3, SHRINE.rarities, 0.0, RandomNumberGenerator.new())
	assert_eq(offers.size(), 1)
