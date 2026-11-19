class_name LevelUpData
extends Resource
## Cómo es la elección al subir de nivel (GDD §5 y §6): cuántas opciones salen, cuántas ranuras de
## armas y runas hay, de qué carpetas salen, cómo gira la ruleta y cuánto cuesta volver a tirar. Los
## valores viven en [code]data/progression/level_up.tres[/code]; aquí todo vale 0 o vacío a propósito.
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

@export_group("reroll")
## Oro que cuesta el primer «volver a tirar» de la partida.
@export_range(0, 1000, 1, "or_greater") var reroll_cost: int = 0
## Cuánto se multiplica el coste con cada uso en la partida.
@export_range(1.0, 5.0, 0.05) var reroll_growth: float = 1.0


## Coste del «volver a tirar» tras [param uses] usos en la partida.
func reroll_cost_at(uses: int) -> int:
	return roundi(reroll_cost * pow(reroll_growth, uses))


## Ranuras de armas abiertas con [param open] según las stats: nunca más de las que hay.
func clamp_weapon_slots(open: int) -> int:
	return clampi(open, 0, max_weapon_slots)


## Ranuras de runas abiertas con [param open] según las stats: nunca más de las que hay.
func clamp_rune_slots(open: int) -> int:
	return clampi(open, 0, max_rune_slots)
