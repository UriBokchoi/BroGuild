extends GutTest
## DamageCalc: daño % y crítico del atacante; esquiva y defensa del defensor (GDD §6).

var _rng: RandomNumberGenerator
var _offense: OffenseData
var _rules: CombatRules


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 1234
	_offense = OffenseData.new()
	_offense.damage = 150.0
	_offense.crit_chance = 0.0
	_offense.crit_damage = 200.0
	_rules = CombatRules.new()
	_rules.armor_for_half_damage = 100.0


func test_without_offense_damage_goes_as_is() -> void:
	var info := DamageCalc.attack(10.0, null, _rng)
	assert_eq(info.amount, 10.0)
	assert_false(info.critical)


func test_damage_percent_multiplies() -> void:
	assert_eq(DamageCalc.attack(10.0, _offense, _rng).amount, 15.0, "10 × 150 %")


func test_critical_hits_multiply_by_crit_damage() -> void:
	_offense.crit_chance = 100.0
	var info := DamageCalc.attack(10.0, _offense, _rng)
	assert_true(info.critical)
	assert_eq(info.amount, 30.0, "10 × 150 % × 200 %")


func test_crit_chance_is_a_probability() -> void:
	_offense.crit_chance = 25.0
	var crits := 0
	for _attack: int in 2000:
		if DamageCalc.attack(10.0, _offense, _rng).critical:
			crits += 1
	assert_between(crits, 400, 600, "≈ 25 % de 2000")


func test_armor_halves_damage_at_its_rule_and_never_makes_immune() -> void:
	assert_eq(DamageCalc.after_armor(40.0, 0.0, _rules), 40.0)
	assert_eq(DamageCalc.after_armor(40.0, 100.0, _rules), 20.0, "100 de defensa = mitad")
	assert_gt(DamageCalc.after_armor(40.0, 10000.0, _rules), 0.0, "nunca inmune")


func test_evasion_is_a_probability() -> void:
	assert_false(DamageCalc.evades(0.0, _rng))
	assert_true(DamageCalc.evades(100.0, _rng))
