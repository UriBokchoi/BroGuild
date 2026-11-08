class_name Player
extends CharacterBody3D
## Jugador: monta el contexto de movimiento, avanza la máquina de estados y mueve el cuerpo.
## Las mecánicas van en sus estados y componentes, nunca aquí (CLAUDE.md, «Nunca»).

@export var stats: StatsComponent
@export var input: PlayerInput
@export var movement: StateMachine
## Estado neutro en el suelo.
@export var ground_state: State
## Estado neutro en el aire.
@export var air_state: State

## Contexto compartido por los estados de movimiento. Fuera de los estados, solo para leer
## (el panel de depuración, por ejemplo).
var context: MovementContext


func _ready() -> void:
	context = MovementContext.new()
	context.body = self
	context.move = stats.get_resolved(MovementData) as MovementData
	context.ground = ground_state
	context.air = air_state
	movement.start(context)


func _physics_process(delta: float) -> void:
	context.wish_direction = input.move_direction()
	# Cada tick, por si una mejora acaba de cambiar estas stats.
	movement.buffer_time = context.move.input_buffer_time
	movement.committed_end_buffer = context.move.action_end_buffer_time
	movement.physics_update(delta)
	move_and_slide()
