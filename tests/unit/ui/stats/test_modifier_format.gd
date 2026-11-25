extends GutTest
## ModifierFormat: describe un modificador con su signo, su tipo, la unidad de la stat si suma (y
## la tiene clara) y el nombre traducido de la stat; con unas stats, el valor de ahora y el de después.

const FixtureData := preload("res://tests/unit/core/stats/stats_test_data.gd")


func test_flat_adds_with_sign() -> void:
	var text := ModifierFormat.describe(StatModifier.create(&"max_health", StatModifier.Kind.FLAT, 20.0))
	assert_string_starts_with(text, "+20 ")
	assert_string_contains(text, String(TranslationServer.translate("STAT_MAX_HEALTH")))


func test_percent_is_shown_as_percent() -> void:
	var text := ModifierFormat.describe(StatModifier.create(&"damage", StatModifier.Kind.PERCENT, 0.1))
	assert_string_starts_with(text, "+10 % ")


func test_negative_values_keep_their_sign() -> void:
	var text := ModifierFormat.describe(StatModifier.create(&"cooldown", StatModifier.Kind.PERCENT, -0.2))
	assert_string_starts_with(text, "−20 % ")


func test_multipliers_use_times() -> void:
	var text := ModifierFormat.describe(StatModifier.create(&"area", StatModifier.Kind.MULTIPLIER, 1.5))
	assert_string_starts_with(text, StatFormat.localize_decimals("×1.5 "))


func test_flat_takes_the_stat_unit() -> void:
	var text := ModifierFormat.describe(StatModifier.create(&"crit_chance", StatModifier.Kind.FLAT, 10.0))
	assert_string_starts_with(text, "+10 % ", "la probabilidad de crítico ya es un %")
	var speed := ModifierFormat.describe(StatModifier.create(&"run_speed", StatModifier.Kind.FLAT, 0.5))
	assert_string_starts_with(speed, StatFormat.localize_decimals("+0.5 m/s "))


func test_changes_say_the_value_now_and_after_once_per_stat() -> void:
	var stats := StatsComponent.new()
	stats.sources.append(FixtureData.new())
	add_child_autofree(stats)
	var modifiers: Array[StatModifier] = [
		StatModifier.create(&"speed", StatModifier.Kind.FLAT, 1.0),
		StatModifier.create(&"speed", StatModifier.Kind.PERCENT, 0.1),
		StatModifier.create(&"jumps", StatModifier.Kind.FLAT, 1.0),
		StatModifier.create(&"luck", StatModifier.Kind.FLAT, 1.0),
	]
	var lines := ModifierFormat.changes(modifiers, stats)
	assert_eq(Array(lines), ["9 m/s → 11 m/s", "", "1 → 2", ""], "(9 + 1) × 1,1; la suerte no la tiene")
	assert_eq(stats.get_value(&"speed"), 9.0, "solo lo calcula")


func test_without_stats_there_are_no_changes() -> void:
	var modifiers: Array[StatModifier] = [StatModifier.create(&"damage", StatModifier.Kind.PERCENT, 0.1)]
	assert_eq(Array(ModifierFormat.changes(modifiers, null)), [""])
	assert_eq(ModifierFormat.describe_changes(modifiers, null), ModifierFormat.describe_all(modifiers), "solo lo que hace")


func test_cards_get_one_line_per_stat_with_its_values() -> void:
	var stats := StatsComponent.new()
	stats.sources.append(FixtureData.new())
	add_child_autofree(stats)
	var modifiers: Array[StatModifier] = [
		StatModifier.create(&"speed", StatModifier.Kind.FLAT, 1.0),
		StatModifier.create(&"speed", StatModifier.Kind.PERCENT, 0.1),
		StatModifier.create(&"luck", StatModifier.Kind.FLAT, 1.0),
	]
	var speed := TranslationServer.translate(StatFormat.name_key(&"speed"))
	assert_eq(
		Array(ModifierFormat.describe_changes(modifiers, stats)),
		["%s 9 m/s → 11 m/s" % speed, ModifierFormat.describe(modifiers[2])],
		"la velocidad una vez, con los dos; la suerte (que no tiene), como siempre"
	)


func test_a_stat_with_two_units_goes_without() -> void:
	# «damage»: un número en las armas y un % en el jugador; depende de a quién se aplique.
	var text := ModifierFormat.describe(StatModifier.create(&"damage", StatModifier.Kind.FLAT, 3.0))
	assert_eq(text, "+3 %s" % TranslationServer.translate(StatFormat.name_key(&"damage")))
