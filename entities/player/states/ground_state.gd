class_name GroundState
extends MovementState
## En el suelo sin ninguna acción en curso: corre hacia la dirección pedida y frena al soltar.
## Si deja de haber suelo sin haber saltado, pasa al aire con coyote time.


func physics_update(delta: float) -> void:
	if not ctx.body.is_on_floor():
		ctx.coyote_left = ctx.move.coyote_time
		machine.transition_to(ctx.air)
		return
	var wants_to_move := ctx.wish_direction != Vector3.ZERO
	var rate := ctx.move.ground_acceleration if wants_to_move else ctx.move.ground_deceleration
	accelerate_horizontal(ctx.wish_direction * ctx.move.run_speed, rate, delta)
