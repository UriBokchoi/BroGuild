class_name JumpState
extends MovementState
## Salto desde el suelo o justo después de dejarlo (coyote time). Da el impulso al entrar y
## pasa al aire en el mismo tick, así que no es una acción con duración.


func can_enter() -> bool:
	return ctx.body.is_on_floor() or ctx.coyote_left > 0.0


func enter(_previous: State) -> void:
	ctx.coyote_left = 0.0
	ctx.body.velocity.y = ctx.move.jump_velocity()


func physics_update(_delta: float) -> void:
	machine.transition_to(ctx.air)
