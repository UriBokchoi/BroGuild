class_name SlideJumpState
extends MovementState
## Slide-jump: Espacio durante el slide. Salta como el salto normal y conserva todo el impulso
## del slide (el control aéreo no lo frena). Solo entra mientras interrumpe a uno de los estados
## de [member State.interrupts] (en la escena, el slide). Pasa al aire en el mismo tick.


func can_enter() -> bool:
	return interrupts.has(machine.current)


func enter(_previous: State) -> void:
	ctx.coyote_left = 0.0
	ctx.body.velocity.y = ctx.move.jump_velocity()


func physics_update(_delta: float) -> void:
	machine.transition_to(ctx.air)
