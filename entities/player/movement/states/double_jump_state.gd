class_name DoubleJumpState
extends MovementState
## Salto en el aire (doble salto). Gasta stamina y uno de los [code]air_jumps[/code], que se
## recuperan al tocar suelo; con más (una mejora o un personaje), triple salto. Con coyote time
## no entra: ese salto es el normal. Da el impulso al entrar y pasa al aire en el mismo tick.


func can_enter() -> bool:
	return (
		not ctx.body.is_on_floor()
		and ctx.coyote_left <= 0.0
		and ctx.air_jumps_used < ctx.move.air_jumps
		and ctx.stamina.can_spend(ctx.move.air_jump_cost)
	)


func enter(_previous: State) -> void:
	ctx.stamina.spend(ctx.move.air_jump_cost)
	ctx.air_jumps_used += 1
	ctx.body.velocity.y = ctx.move.air_jump_velocity()


func physics_update(_delta: float) -> void:
	machine.transition_to(ctx.air)
