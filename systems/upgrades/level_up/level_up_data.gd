class_name LevelUpData
extends Resource
## Cómo es la elección al subir de nivel (GDD §5 y §6): cuántas opciones salen, cuántas ranuras de
## armas y runas hay, de qué carpetas salen, cómo gira la ruleta, cuánto cuesta volver a tirar y cómo
## es el doble o nada. Los valores viven en [code]data/progression/level_up.tres[/code]; aquí todo
## vale 0 o vacío a propósito.
##
## Cuántas ranuras están abiertas lo dicen las stats del jugador [code]weapon_slots[/code] y
## [code]rune_slots[/code] ([ProgressionData]): empieza con unas pocas y el resto se desbloquean.

## Rarezas de las mejoras ([WeightedTable] de [Rarity]).
@export var rarities: WeightedTable
## Opciones en cada elección.
@export_range(1, 6, 1) var choices: int = 0
## Ranuras de armas que hay, abiertas o cerradas (las que muestra el HUD).
@export_range(1, 12, 1) var max_weapon_slots: int = 0
## Ranuras de runas que hay, abiertas o cerradas.
@export_range(1, 12, 1) var max_rune_slots: int = 0
## Carpeta de las armas que pueden salir (más adelante, solo las desbloqueadas).
@export_dir var weapons_dir: String = ""
## Carpeta de las runas que pueden salir.
@export_dir var runes_dir: String = ""

@export_group("roulette")
## Segundos que gira la primera carta de mejora antes de pararse en su rareza.
@export_range(0.0, 5.0, 0.05, "suffix:s") var spin_time: float = 0.0
## Segundos de más que gira cada carta siguiente: se paran una tras otra.
@export_range(0.0, 2.0, 0.05, "suffix:s") var spin_stagger: float = 0.0
## Vueltas enteras a las rarezas antes de pararse.
@export_range(0, 10, 1) var spin_loops: int = 0

@export_group("double_or_nothing")
## Probabilidad de ganar el doble o nada sin Suerte (0,5 = la mitad).
@export_range(0.0, 1.0, 0.01) var double_chance: float = 0.0
## Suerte con la que se gana la mitad de lo que falta hasta el 100 % (nunca llega: con el doble,
## dos tercios de lo que falta).
@export_range(1.0, 1000.0, 1.0, "or_greater") var double_luck_half: float = 1.0
## Segundos que gira la carta apostada entre su rareza y la siguiente, y vueltas que da.
@export_range(0.0, 5.0, 0.05, "suffix:s") var double_spin_time: float = 0.0
@export_range(0, 20, 1) var double_spin_loops: int = 0
## Segundos que se ve el resultado antes de seguir.
@export_range(0.0, 5.0, 0.05, "suffix:s") var double_result_time: float = 0.0

@export_group("reroll")
## Oro que cuesta el primer «volver a tirar» de la partida.
@export_range(0, 1000, 1, "or_greater") var reroll_cost: int = 0
## Cuánto se multiplica el coste con cada uso en la partida.
@export_range(1.0, 5.0, 0.05) var reroll_growth: float = 1.0


## Probabilidad de ganar el doble o nada con [param luck] puntos de Suerte: la base y, encima, la
## parte de lo que falta hasta el 100 % que da la Suerte ([member double_luck_half]).
func double_chance_with(luck: float) -> float:
	var boost := maxf(luck, 0.0) / (maxf(luck, 0.0) + double_luck_half)
	return double_chance + (1.0 - double_chance) * boost


## La rareza que sigue a [param rarity] en [member rarities] (la de un doble o nada ganado), o
## [code]null[/code] si es la última o no está.
func next_rarity(rarity: Rarity) -> Rarity:
	if rarity == null or rarities == null:
		return null
	for index: int in rarities.entries.size() - 1:
		if (rarities.entries[index] as Rarity).id == rarity.id:
			return rarities.entries[index + 1] as Rarity
	return null


## Coste del «volver a tirar» tras [param uses] usos en la partida.
func reroll_cost_at(uses: int) -> int:
	return roundi(reroll_cost * pow(reroll_growth, uses))


## Ranuras de armas abiertas con [param open] según las stats: nunca más de las que hay.
func clamp_weapon_slots(open: int) -> int:
	return clampi(open, 0, max_weapon_slots)


## Ranuras de runas abiertas con [param open] según las stats: nunca más de las que hay.
func clamp_rune_slots(open: int) -> int:
	return clampi(open, 0, max_rune_slots)
