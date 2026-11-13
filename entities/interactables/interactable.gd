class_name Interactable
extends Area3D
## Algo con lo que se interactúa pulsando «interactuar» cerca (una armería, un cofre, una
## tragaperras…). Un [Interactor] lo detecta, muestra [member prompt_key] y lo activa; qué pasa
## al activarlo lo decide quien escucha [signal interacted]. Su capa de física es
## [code]interactable[/code].

## Lo activó [param by] (quien interactúa, p. ej. el jugador).
signal interacted(by: Node3D)

## Clave de traducción de lo que hace (se muestra junto a la tecla).
@export var prompt_key: StringName = &""
## Desactivado, no se puede usar ni se muestra.
@export var enabled: bool = true


func _ready() -> void:
	# Lo detecta el Interactor: este solo tiene que ser detectable.
	monitoring = false
	monitorable = true


## Lo activa [param by].
func interact(by: Node3D) -> void:
	if enabled:
		interacted.emit(by)
