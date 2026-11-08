class_name AirState
extends MovementState
## En el aire sin ninguna acción en curso: cae con la gravedad, con control aéreo, hasta tocar
## suelo. Mientras, se agota el coyote time.


func physics_update(delta: float) -> void:
	if ctx.body.is_on_floor():
		machine.transition_to(ctx.ground)
		return
	ctx.coyote_left = maxf(ctx.coyote_left - delta, 0.0)
	apply_gravity(delta)
	apply_air_control(delta)
