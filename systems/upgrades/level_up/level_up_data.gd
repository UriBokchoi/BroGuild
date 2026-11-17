class_name LevelUpData
extends Resource
## Cómo es la elección al subir de nivel (GDD §6): cuántas opciones salen, cuántas ranuras de armas
## y runas hay y de qué carpetas salen. Los valores viven en
## [code]data/progression/level_up.tres[/code]; aquí todo vale 0 o vacío a propósito.
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


## Ranuras de armas abiertas con [param open] según las stats: nunca más de las que hay.
func clamp_weapon_slots(open: int) -> int:
	return clampi(open, 0, max_weapon_slots)


## Ranuras de runas abiertas con [param open] según las stats: nunca más de las que hay.
func clamp_rune_slots(open: int) -> int:
	return clampi(open, 0, max_rune_slots)
