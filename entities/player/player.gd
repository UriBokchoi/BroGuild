class_name Player
extends CharacterBody3D
## Jugador: monta el contexto de movimiento, avanza la máquina de estados y mueve el cuerpo.
## Avisa a la interfaz de su vida y de su muerte (al morir se queda quieto y sus armas paran). Las
## mecánicas van en sus estados y componentes, nunca aquí (CLAUDE.md, «Nunca»).

@export var stats: StatsComponent
@export var stamina: StaminaComponent
@export var health: HealthComponent
@export var weapons: WeaponInventory
@export var input: PlayerInput
@export var movement: StateMachine
## Sensor de paredes para el salto en pared.
@export var wall_sensor: WallSensor
## Sensor de bordes para el mantle.
@export var ledge_sensor: LedgeSensor
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
	context.stamina = stamina
	context.wall_sensor = wall_sensor
	context.ledge_sensor = ledge_sensor
	context.ground = ground_state
	context.air = air_state
	input.action_pressed.connect(context.record_press)
	movement.start(context)
	health.health_changed.connect(EventBus.player_health_changed.emit)
	health.died.connect(_on_died)
	# La vida avisó en su _ready, antes de esta conexión: se repite para la interfaz.
	EventBus.player_health_changed.emit(health.get_current(), health.get_maximum())


func _physics_process(delta: float) -> void:
	context.elapsed += delta
	context.wish_direction = input.move_direction()
	context.view_forward = input.view_forward()
	context.slide_held = input.is_held(InputActions.SLIDE)
	# Cada tick, por si una mejora acaba de cambiar estas stats.
	movement.buffer_time = context.move.input_buffer_time
	movement.committed_end_buffer = context.move.action_end_buffer_time
	movement.physics_update(delta)
	move_and_slide()


## Lleva al jugador a [param feet] (la posición de sus pies) parado y sin el arrastre de la
## interpolación, como si apareciera ahí (teletransportes).
func teleport_to(feet: Vector3) -> void:
	global_position = feet
	velocity = Vector3.ZERO
	reset_physics_interpolation()


## Muerto, se queda quieto y sus armas paran. La pantalla de resultados y el reinicio llegarán con
## su tarea.
func _on_died() -> void:
	set_physics_process(false)
	velocity = Vector3.ZERO
	weapons.process_mode = Node.PROCESS_MODE_DISABLED
	EventBus.player_died.emit()
