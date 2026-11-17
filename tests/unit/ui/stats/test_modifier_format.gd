extends GutTest
## ModifierFormat: describe un modificador con su signo, su tipo y el nombre traducido de la stat.


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
	assert_string_starts_with(text, "×1.5 ")
