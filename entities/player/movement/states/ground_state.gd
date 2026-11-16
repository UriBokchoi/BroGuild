class_name GroundState
extends MovementState
## En el suelo sin ninguna acción en curso: acelera poco a poco hacia la dirección pedida (a la
## velocidad normal o, tras unos segundos moviéndote, a la de sprint) y frena al soltar. Si deja de
## haber suelo sin haber saltado, pasa al aire con coyote time. Tocar suelo devuelve los saltos y
## los dashes en el aire.


func enter(_previous: State) -> void:
	touch_ground()


func physics_update(delta: float) -> void:
	if not ctx.body.is_on_floor():
		ctx.coyote_left = ctx.move.coyote_time
		machine.transition_to(ctx.air)
		return
	track_sprint(delta)
	var wants_to_move := ctx.wish_direction != Vector3.ZERO
	var rate := ctx.move.ground_acceleration if wants_to_move else ctx.move.ground_deceleration
	accelerate_horizontal(ctx.wish_direction * ctx.ground_speed(), rate, delta)
