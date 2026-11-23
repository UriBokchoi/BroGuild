class_name LevelData
extends Resource
## Un nivel que se puede jugar: su nombre, su escena y lo que se cuenta de él al elegirlo (cómo se
## gana y su lore). Añadir un nivel es crear su [code].tres[/code] en [code]data/levels/[/code] con su
## escena (la del mapa, con los sistemas de la partida). El lore completo vive en
## [code]docs/LORE.md[/code]; aquí solo las claves de los textos cortos que salen en el juego.

## Identificador estable (guardado, desbloqueos).
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]LEVEL_BROSQUE_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de cómo se gana (p. ej. vencer a su jefe). Vacía: no se dice.
@export var goal_key: StringName = &""
## Clave de traducción de su descripción con lore. Vacía: no se dice.
@export var lore_key: StringName = &""
## Escena del nivel. Vacía: aún no existe (sale como «Próximamente»).
@export var scene: PackedScene


## ¿Se puede jugar ya?
func is_available() -> bool:
	return scene != null
