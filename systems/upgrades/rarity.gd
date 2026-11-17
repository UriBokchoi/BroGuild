class_name Rarity
extends WeightedEntry
## Una rareza de las mejoras (común, rara, improbable, de leyenda, mítica): cuánto sale (su peso),
## su color (el borde de la carta), cuántas stats del arma o runa toca y cuánto más fuertes son.
## Las rarezas viven en [code]data/rarities/[/code]; la tabla que se usa, en
## [code]data/rarities/rarities.tres[/code]. Más adelante, la Suerte desplazará sus pesos.

## Identificador estable.
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]RARITY_COMMON[/code]).
@export var name_key: StringName = &""
## Color con el que se reconoce (borde de la carta, nombre).
@export var color: Color = Color.WHITE
## Stats que toca como mínimo (0 = todas las que tenga).
@export_range(0, 10, 1) var min_stats: int = 0
## Stats que toca como máximo (0 = todas las que tenga).
@export_range(0, 10, 1) var max_stats: int = 0
## Multiplica la mejora base de cada stat.
@export_range(0.1, 10.0, 0.05) var power: float = 1.0


## Cuántas stats toca, al azar, de [param available].
func roll_count(available: int, rng: RandomNumberGenerator) -> int:
	var top := available if max_stats <= 0 else mini(max_stats, available)
	var bottom := top if min_stats <= 0 else mini(min_stats, top)
	return rng.randi_range(bottom, top)
