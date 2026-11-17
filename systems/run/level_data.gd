class_name LevelData
extends Resource
## Un nivel que se puede jugar: su nombre y su escena. Añadir un nivel es crear su [code].tres[/code]
## en [code]data/levels/[/code] con su escena (la del mapa, con los sistemas de la partida).

## Identificador estable (guardado, desbloqueos).
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]LEVEL_BROSQUE_NAME[/code]).
@export var name_key: StringName = &""
## Escena del nivel. Vacía: aún no existe (sale como «Próximamente»).
@export var scene: PackedScene


## ¿Se puede jugar ya?
func is_available() -> bool:
	return scene != null
