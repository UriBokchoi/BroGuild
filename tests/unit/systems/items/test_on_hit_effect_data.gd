extends GutTest
## Los efectos al golpear de los objetos: sus líneas en las fichas llevan sus números (y la
## probabilidad crece con las copias); el veneno quita en total la parte de cada tick por los ticks.

const PREWORKOUT := preload("res://data/items/expired_preworkout.tres")
const CABLE := preload("res://data/items/frayed_cable.tres")
const SPRAY := preload("res://data/items/cold_spray.tres")


func test_poison_line_and_total() -> void:
	var poison := PREWORKOUT.on_hit[0] as PoisonOnHit
	assert_almost_eq(poison.total_share(), 0.6, 0.001, "10 % cada medio segundo durante 3 s")
	var line := poison.describe()
	assert_string_contains(line, "15")
	assert_string_contains(line, "60")
	assert_string_contains(poison.describe(2), "30", "dos copias, el doble de probabilidad")


func test_chain_and_slow_lines() -> void:
	var chain := CABLE.on_hit[0] as ChainOnHit
	assert_string_contains(chain.describe(), str(chain.jumps))
	assert_string_contains(chain.describe(), "50")
	var slow := SPRAY.on_hit[0] as SlowOnHit
	assert_string_contains(slow.describe(), "40", "frena un 40 %")


func test_items_list_their_effects() -> void:
	assert_eq(PREWORKOUT.effect_lines().size(), 1)
	assert_eq(PREWORKOUT.effect_lines()[0], PREWORKOUT.on_hit[0].describe())
