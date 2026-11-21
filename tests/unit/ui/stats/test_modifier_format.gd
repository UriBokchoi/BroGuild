extends GutTest
## ModifierFormat: describe un modificador con su signo, su tipo, la unidad de la stat si suma (y
## la tiene clara) y el nombre traducido de la stat.


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


func test_a_stat_with_two_units_goes_without() -> void:
	# «damage»: un número en las armas y un % en el jugador; depende de a quién se aplique.
	var text := ModifierFormat.describe(StatModifier.create(&"damage", StatModifier.Kind.FLAT, 3.0))
	assert_eq(text, "+3 %s" % TranslationServer.translate(StatFormat.name_key(&"damage")))
