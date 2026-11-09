class_name GroundState
extends MovementState
## En el suelo sin ninguna acción en curso. Si deja de haber suelo, pasa al aire.


func physics_update(_delta: float) -> void:
	if not ctx.body.is_on_floor():
		machine.transition_to(ctx.air)
