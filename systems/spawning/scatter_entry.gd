class_name ScatterEntry
extends Resource
## Qué repartir por el nivel y cuántos (ver [BreakableScatter]).

## Escena que se reparte (una calavera, una bolsita…).
@export var scene: PackedScene
## Cuántas.
@export_range(0, 500, 1) var count: int = 0
