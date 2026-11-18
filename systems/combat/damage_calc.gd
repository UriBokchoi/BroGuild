class_name DamageCalc
extends RefCounted
## Fórmulas de daño del GDD (§6), puras y con el azar inyectado para poder probarlas con semilla.
## Atacante: daño base × daño % y, si sale crítico, × daño crítico %; su empuje, × empuje %.
## Defensor: la esquiva evita el golpe entero y la defensa lo reduce con rendimientos decrecientes.


## Golpe de [param base_damage] con las stats de ataque de [param offense] (null = sin modificar),
## que empuja [param knockback] (por el empuje % del atacante).
static func attack(
	base_damage: float, offense: OffenseData, rng: RandomNumberGenerator, from: Node = null, knockback: Vector3 = Vector3.ZERO
) -> DamageInfo:
	if offense == null:
		return DamageInfo.create(base_damage, false, from, knockback)
	var critical := rng.randf() * 100.0 < offense.crit_chance
	var amount := base_damage * offense.damage / 100.0
	if critical:
		amount *= offense.crit_damage / 100.0
	return DamageInfo.create(amount, critical, from, knockback * offense.knockback / 100.0)


## Empuje de [param strength] m/s en el suelo desde [param from] hacia [param to] (cero si están en el
## mismo sitio).
static func push(from: Vector3, to: Vector3, strength: float) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if strength <= 0.0 or flat.length_squared() < 0.0001:
		return Vector3.ZERO
	return flat.normalized() * strength


## ¿Esquiva el golpe con [param evasion] % de esquiva?
static func evades(evasion: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() * 100.0 < evasion


## Daño que queda de [param amount] tras [param armor] puntos de defensa.
static func after_armor(amount: float, armor: float, rules: CombatRules) -> float:
	var k := rules.armor_for_half_damage
	return amount * k / (k + maxf(armor, 0.0))
