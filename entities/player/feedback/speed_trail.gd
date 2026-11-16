class_name SpeedTrail
extends GPUParticles3D
## Estela de partículas detrás del personaje mientras el movimiento está en uno de
## [member trail_states] (dash, slide…). Solo visual: escucha [signal StateMachine.state_changed].
## El aspecto de las partículas se ajusta en la escena.

@export var machine: StateMachine
## Estados en los que deja estela.
@export var trail_states: Array[Node] = []


func _ready() -> void:
	emitting = false
	machine.state_changed.connect(_on_state_changed)


func _on_state_changed(_previous: State, current: State) -> void:
	emitting = trail_states.has(current)
