class_name MovementData
extends Resource
## Parámetros del movimiento del jugador. Los valores viven en
## [code]data/player/movement.tres[/code]; aquí todo vale 0 a propósito (ver DECISIONES,
## «Valores de datos solo en el .tres»). Cada número es una stat: mejoras y personajes lo
## modifican con [StatModifier] por su nombre.

@export_group("run")
## Velocidad de carrera en el suelo.
@export_range(0.0, 30.0, 0.1, "or_greater", "suffix:m/s") var run_speed: float = 0.0
## Aceleración hacia la velocidad de carrera mientras pides una dirección.
@export_range(0.0, 200.0, 0.5, "or_greater", "suffix:m/s²") var ground_acceleration: float = 0.0
## Frenada en el suelo cuando sueltas la dirección.
@export_range(0.0, 200.0, 0.5, "or_greater", "suffix:m/s²") var ground_deceleration: float = 0.0
## Velocidad a la que el modelo se gira hacia donde te mueves (solo visual).
@export_range(0.0, 3600.0, 1.0, "or_greater", "radians_as_degrees", "suffix:°/s")
var turn_speed: float = 0.0

@export_group("jump")
## Altura del salto. Junto con [member jump_time_to_apex] define también la gravedad.
@export_range(0.5, 10.0, 0.05, "or_greater", "suffix:m") var jump_height: float = 0.0
## Segundos que tarda el salto en llegar a la cima.
@export_range(0.1, 1.5, 0.01, "or_greater", "suffix:s") var jump_time_to_apex: float = 0.0
## Velocidad máxima de caída.
@export_range(1.0, 100.0, 0.5, "or_greater", "suffix:m/s") var max_fall_speed: float = 0.0
## Segundos tras dejar el suelo (sin saltar) en los que todavía puedes saltar.
@export_range(0.0, 0.5, 0.01, "or_greater", "suffix:s") var coyote_time: float = 0.0
## Saltos en el aire antes de tocar suelo (1 = doble salto, 2 = triple salto…).
@export_range(0, 5, 1, "or_greater") var air_jumps: int = 0
## Altura de cada salto en el aire.
@export_range(0.5, 10.0, 0.05, "or_greater", "suffix:m") var air_jump_height: float = 0.0
## Cargas de stamina que gasta cada salto en el aire.
@export_range(0.0, 3.0, 0.5, "or_greater") var air_jump_cost: float = 0.0

@export_group("dash")
## Velocidad del dash.
@export_range(0.0, 100.0, 0.5, "or_greater", "suffix:m/s") var dash_speed: float = 0.0
## Segundos que dura el dash.
@export_range(0.05, 1.0, 0.01, "or_greater", "suffix:s") var dash_duration: float = 0.0
## Velocidad horizontal máxima con la que sales del dash (lo que sobra se pierde al terminar).
@export_range(0.0, 100.0, 0.5, "or_greater", "suffix:m/s") var dash_exit_speed: float = 0.0
## Cargas de stamina que gasta el dash.
@export_range(0.0, 3.0, 0.5, "or_greater") var dash_cost: float = 0.0
## Velocidad del picado (dash hacia abajo).
@export_range(0.0, 100.0, 0.5, "or_greater", "suffix:m/s") var down_dash_speed: float = 0.0
## Segundos que dura el picado (antes, si tocas suelo).
@export_range(0.05, 1.0, 0.01, "or_greater", "suffix:s") var down_dash_duration: float = 0.0
## Segundos tras el primer Shift en los que el segundo, sin dirección, hace el picado.
@export_range(0.05, 1.0, 0.01, "or_greater", "suffix:s") var down_dash_window: float = 0.0
## Cargas de stamina que gasta el picado (además del dash del primer Shift).
@export_range(0.0, 3.0, 0.5, "or_greater") var down_dash_cost: float = 0.0

@export_group("air")
## Aceleración hacia la dirección pedida en el aire. No frena el impulso que ya llevas por
## encima de la velocidad de carrera.
@export_range(0.0, 200.0, 0.5, "or_greater", "suffix:m/s²") var air_acceleration: float = 0.0
## Frenada en el aire cuando no pides dirección (0 = conservas todo el impulso).
@export_range(0.0, 200.0, 0.5, "or_greater", "suffix:m/s²") var air_deceleration: float = 0.0

@export_group("input")
## Segundos que espera una acción pulsada que aún no puede hacerse (el jump buffer).
@export_range(0.0, 0.5, 0.01, "or_greater", "suffix:s") var input_buffer_time: float = 0.0
## Si a una acción en curso le queda menos que esto, lo que pulses se guarda para cuando
## termine; si le queda más, se pierde.
@export_range(0.0, 0.5, 0.01, "suffix:s") var action_end_buffer_time: float = 0.0


## Gravedad con la que un salto de [member jump_height] tarda [member jump_time_to_apex] en
## llegar a la cima.
func gravity() -> float:
	return 2.0 * jump_height / (jump_time_to_apex * jump_time_to_apex)


## Velocidad vertical inicial de un salto de [member jump_height].
func jump_velocity() -> float:
	return 2.0 * jump_height / jump_time_to_apex


## Velocidad vertical inicial de un salto en el aire de [member air_jump_height], con la misma
## gravedad que el salto normal.
func air_jump_velocity() -> float:
	return sqrt(2.0 * gravity() * air_jump_height)
