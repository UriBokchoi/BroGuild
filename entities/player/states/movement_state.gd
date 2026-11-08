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
