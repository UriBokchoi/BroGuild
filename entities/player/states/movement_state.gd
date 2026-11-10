@abstract
class_name MovementState
extends State
## Base de los estados de movimiento del jugador: acceso tipado al contexto compartido y
## utilidades comunes. Cada mecánica va en su propio estado.

var ctx: MovementContext


func setup(context: Object) -> void:
	ctx = context as MovementContext


## Vuelve al estado neutro que toca, suelo o aire. Para cuando termina una acción.
func settle() -> void:
	machine.transition_to(ctx.ground if ctx.body.is_on_floor() else ctx.air)


## Aplica la gravedad de los datos sin pasar de la velocidad máxima de caída.
func apply_gravity(delta: float) -> void:
	var fall := ctx.body.velocity.y - ctx.move.gravity() * delta
	ctx.body.velocity.y = maxf(fall, -ctx.move.max_fall_speed)


## Control en el aire: acelera hacia la dirección pedida sin frenar el impulso que ya se lleva
## por encima de la velocidad de carrera (o de sprint). Sin dirección, frena con
## [code]air_deceleration[/code].
func apply_air_control(delta: float) -> void:
	var wish := ctx.wish_direction
	if wish == Vector3.ZERO:
		accelerate_horizontal(Vector3.ZERO, ctx.move.air_deceleration, delta)
		return
	var speed := maxf(ctx.ground_speed(), horizontal_speed())
	accelerate_horizontal(wish * speed, ctx.move.air_acceleration, delta)


## Tocar suelo (de pie o deslizando) devuelve los saltos y dashes en el aire y reinicia la cadena
## de saltos en pared.
func touch_ground() -> void:
	ctx.air_jumps_used = 0
	ctx.air_dashes_used = 0
	ctx.wall_jumps_chained = 0


## Cuenta el tiempo seguido pidiendo dirección, que lleva al sprint; soltarla lo reinicia.
func track_sprint(delta: float) -> void:
	if ctx.wish_direction == Vector3.ZERO:
		ctx.sprint_time = 0.0
	else:
		ctx.sprint_time += delta


## Lleva la velocidad horizontal hacia [param target] a [param rate] m/s², sin tocar la vertical.
func accelerate_horizontal(target: Vector3, rate: float, delta: float) -> void:
	var velocity := ctx.body.velocity
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	ctx.body.velocity = Vector3(horizontal.x, velocity.y, horizontal.z)


func horizontal_speed() -> float:
	return Vector2(ctx.body.velocity.x, ctx.body.velocity.z).length()
