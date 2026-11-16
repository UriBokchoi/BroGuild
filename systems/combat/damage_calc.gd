class_name DamageCalc
extends RefCounted
## Fórmulas de daño del GDD (§6), puras y con el azar inyectado para poder probarlas con semilla.
## Atacante: daño base × daño % y, si sale crítico, × daño crítico %. Defensor: la esquiva evita el
## golpe entero y la defensa lo reduce con rendimientos decrecientes.


## Golpe de [param base_damage] con las stats de ataque de [param offense] (null = sin modificar).
static func attack(
	base_damage: float, offense: OffenseData, rng: RandomNumberGenerator, from: Node = null
) -> DamageInfo:
	if offense == null:
		return DamageInfo.create(base_damage, false, from)
	var critical := rng.randf() * 100.0 < offense.crit_chance
	var amount := base_damage * offense.damage / 100.0
	if critical:
		amount *= offense.crit_damage / 100.0
	return DamageInfo.create(amount, critical, from)


## ¿Esquiva el golpe con [param evasion] % de esquiva?
static func evades(evasion: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() * 100.0 < evasion


## Daño que queda de [param amount] tras [param armor] puntos de defensa.
static func after_armor(amount: float, armor: float, rules: CombatRules) -> float:
	var k := rules.armor_for_half_damage
	return amount * k / (k + maxf(armor, 0.0))
