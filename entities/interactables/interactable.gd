class_name Interactable
extends Area3D
## Algo con lo que se interactúa pulsando «interactuar» cerca (una armería, un cofre, una
## tragaperras…). Un [Interactor] lo detecta, muestra [member prompt_key] y lo activa; qué pasa
## al activarlo lo decide quien escucha [signal interacted]. Su capa de física es
## [code]interactable[/code]. Avisa de si es el que se usaría ahora ([signal focus_changed]) y de si
## se puede usar ([signal enabled_changed]), para el aviso visual ([InteractHint]).

## Lo activó [param by] (quien interactúa, p. ej. el jugador).
signal interacted(by: Node3D)
## Pasó a ser (o dejó de ser) el que se usaría ahora con «interactuar»: el más cercano al jugador.
signal focus_changed(focused: bool)
## Se puede usar, o ya no.
signal enabled_changed(enabled: bool)

## Clave de traducción de lo que hace (se muestra junto a la tecla).
@export var prompt_key: StringName = &""
## Desactivado, no se puede usar ni se muestra.
@export var enabled: bool = true:
	set(value):
		if enabled == value:
			return
		enabled = value
		enabled_changed.emit(value)

var _focused: bool = false


func _ready() -> void:
	# Lo detecta el Interactor: este solo tiene que ser detectable.
	monitoring = false
	monitorable = true


## Lo activa [param by].
func interact(by: Node3D) -> void:
	if enabled:
		interacted.emit(by)


## Lo marca (o desmarca) como el que se usaría ahora. Lo llama el [Interactor].
func set_focused(focused: bool) -> void:
	if focused == _focused:
		return
	_focused = focused
	focus_changed.emit(focused)


func is_focused() -> bool:
	return _focused
