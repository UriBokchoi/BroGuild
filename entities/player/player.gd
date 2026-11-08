class_name Player
extends CharacterBody3D
## Jugador: monta el contexto de movimiento, avanza la máquina de estados y mueve el cuerpo.
## Las mecánicas van en sus estados y componentes, nunca aquí (CLAUDE.md, «Nunca»).

@export var stats: StatsComponent
@export var movement: StateMachine
## Estado neutro en el suelo.
@export var ground_state: State
## Estado neutro en el aire.
@export var air_state: State

var _move: MovementData


func _ready() -> void:
	_move = stats.get_resolved(MovementData) as MovementData
	var context := MovementContext.new()
	context.body = self
	context.move = _move
	context.ground = ground_state
	context.air = air_state
	movement.start(context)


func _physics_process(delta: float) -> void:
	# Cada tick, por si una mejora acaba de cambiar estas stats.
	movement.buffer_time = _move.input_buffer_time
	movement.committed_end_buffer = _move.action_end_buffer_time
	movement.physics_update(delta)
	move_and_slide()
