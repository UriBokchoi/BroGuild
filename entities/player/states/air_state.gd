class_name AirState
extends MovementState
## En el aire sin ninguna acción en curso: cae con la gravedad hasta tocar suelo.


func physics_update(delta: float) -> void:
	if ctx.body.is_on_floor():
		machine.transition_to(ctx.ground)
		return
	apply_gravity(delta)
