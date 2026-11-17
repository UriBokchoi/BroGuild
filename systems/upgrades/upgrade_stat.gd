class_name UpgradeStat
extends Resource
## Una stat que puede mejorar un arma o una runa al subir de nivel, con su mejora base (la de una
## carta común) y lo a menudo que sale ([member weight]); la rareza de la carta la multiplica
## ([member Rarity.power]).

## Nombre de la stat ([code]damage[/code], [code]projectiles[/code], [code]area[/code]…).
@export var stat: StringName = &""
## Cómo se aplica (plano, %, multiplicador).
@export var kind: StatModifier.Kind = StatModifier.Kind.FLAT
## Mejora de una carta común (con multiplicador, el factor: 0,92 = un 8 % menos).
@export var value: float = 0.0
## Si la mejora va en números enteros (proyectiles, rebotes): se redondea, y nunca a menos de 1.
@export var whole_numbers: bool = false
## Peso al elegir qué stats toca una mejora (1 = como las demás; 0,5 = la mitad de veces). Con 0, solo
## en la mejora estándar.
@export_range(0.0, 10.0, 0.05) var weight: float = 1.0


## El modificador con la fuerza [param power] (1 = común).
func modifier(power: float) -> StatModifier:
	# Un multiplicador escala lo que se aleja de 1 (×0,92 con el doble de fuerza es ×0,84).
	var amount := 1.0 + (value - 1.0) * power if kind == StatModifier.Kind.MULTIPLIER else value * power
	if whole_numbers:
		amount = signf(amount) * maxf(roundf(absf(amount)), 1.0)
	return StatModifier.create(stat, kind, amount)
