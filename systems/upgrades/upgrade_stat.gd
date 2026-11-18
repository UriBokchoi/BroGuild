class_name UpgradeStat
extends Resource
## Una stat que puede mejorar un arma o una runa al subir de nivel. La mejora es [member fixed] más
## [member value] por la fuerza de la rareza de la carta ([member Rarity.power]: la común, 0,6; la
## rara, 1). Sin parte fija, [member value] es la mejora de una carta rara.

## Nombre de la stat ([code]damage[/code], [code]projectiles[/code], [code]area[/code]…).
@export var stat: StringName = &""
## Cómo se aplica (plano, %, multiplicador).
@export var kind: StatModifier.Kind = StatModifier.Kind.FLAT
## Parte que crece con la rareza (con multiplicador, el factor de una carta rara: 0,92 = un 8 %
## menos).
@export var value: float = 0.0
## Parte que no cambia con la rareza, sumada a la otra (no vale para los multiplicadores). Hace que
## las rarezas se separen menos: Multiplicidad va de +1 la común a +2,2 la mítica.
@export var fixed: float = 0.0
## Redondeo de la mejora: 0,1 = a un decimal; 0 = sin redondear.
@export_range(0.0, 1.0, 0.01) var step: float = 0.0
## Si la mejora va en números enteros (proyectiles de un arma, rebotes): se redondea, y nunca a
## menos de 1.
@export var whole_numbers: bool = false


## El modificador con la fuerza [param power] (1 = rara).
func modifier(power: float) -> StatModifier:
	# Un multiplicador escala lo que se aleja de 1 (×0,92 con el doble de fuerza es ×0,84).
	var amount := 1.0 + (value - 1.0) * power if kind == StatModifier.Kind.MULTIPLIER else fixed + value * power
	if step > 0.0:
		amount = snappedf(amount, step)
	if whole_numbers:
		amount = signf(amount) * maxf(roundf(absf(amount)), 1.0)
	return StatModifier.create(stat, kind, amount)
