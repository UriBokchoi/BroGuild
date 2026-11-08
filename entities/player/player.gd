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

var _context: MovementContext


func _ready() -> void:
	_context = MovementContext.new()
	_context.body = self
	_context.move = stats.get_resolved(MovementData) as MovementData
	_context.ground = ground_state
	_context.air = air_state
	movement.start(_context)


func _physics_process(delta: float) -> void:
	_context.wish_direction = input.move_direction()
	# Cada tick, por si una mejora acaba de cambiar estas stats.
	movement.buffer_time = _context.move.input_buffer_time
	movement.committed_end_buffer = _context.move.action_end_buffer_time
	movement.physics_update(delta)
	move_and_slide()
