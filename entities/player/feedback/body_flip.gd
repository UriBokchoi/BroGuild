class_name BodyFlip
extends Node
## Mortal hacia delante al entrar en uno de [member flip_states] (el doble salto), si el personaje lo
## tiene ([member CharacterData.air_jump_flip], el Pícaro). Solo visual: gira el modelo sobre su eje
## lateral; el cuerpo físico no gira.

@export var machine: StateMachine
## De quién se mira el personaje.
@export var player: Player
## Modelo que da la vuelta.
@export var visual: Node3D
## Estados que la provocan.
@export var flip_states: Array[Node] = []
## Segundos que dura la vuelta.
@export_range(0.05, 2.0, 0.01, "suffix:s") var flip_time: float = 0.4

var _flip: Tween


func _ready() -> void:
	machine.state_changed.connect(_on_state_changed)


## ¿Está dando la vuelta?
func is_flipping() -> bool:
	return _flip != null and _flip.is_running()


func _on_state_changed(_previous: State, current: State) -> void:
	if not flip_states.has(current) or player.character == null or not player.character.air_jump_flip:
		return
	if _flip:
		_flip.kill()
	visual.rotation.x = 0.0
	# Hacia delante es −Z: la cabeza va hacia delante girando en negativo sobre X.
	_flip = create_tween()
	_flip.tween_property(visual, ^"rotation:x", -TAU, flip_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flip.tween_callback(func() -> void: visual.rotation.x = 0.0)
