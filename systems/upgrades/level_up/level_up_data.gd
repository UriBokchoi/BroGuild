class_name LevelUpData
extends Resource
## Cómo es la elección al subir de nivel (GDD §6): cuántas opciones salen, cuántas armas y runas
## se pueden llevar a la vez y de qué carpetas salen. Los valores viven en
## [code]data/progression/level_up.tres[/code]; aquí todo vale 0 o vacío a propósito.

## Opciones en cada elección.
@export_range(1, 6, 1) var choices: int = 0
## Armas que se pueden llevar a la vez.
@export_range(1, 12, 1) var weapon_slots: int = 0
## Runas que se pueden llevar a la vez.
@export_range(1, 12, 1) var rune_slots: int = 0
## Carpeta de las armas que pueden salir (más adelante, solo las desbloqueadas).
@export_dir var weapons_dir: String = ""
## Carpeta de las runas que pueden salir.
@export_dir var runes_dir: String = ""
