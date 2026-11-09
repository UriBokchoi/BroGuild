class_name DashJumpState
extends MovementState
## Dash-jump: Espacio justo después de un dash hecho en el suelo (ventana
## [code]dash_jump_window[/code], con aviso visual). Salto largo que recupera la velocidad del
## dash en su dirección; el control aéreo la conserva. Gasta stamina además del dash. En la
## escena va por encima del doble salto y del slide-jump, y puede interrumpir al slide (dash →
## slide → dash-jump). Pasa al aire en el mismo tick.


func can_enter() -> bool:
	return ctx.is_dash_jump_open() and ctx.stamina.can_spend(ctx.move.dash_jump_cost)


func enter(_previous: State) -> void:
	ctx.stamina.spend(ctx.move.dash_jump_cost)
	# Se gasta la ventana: un dash, un dash-jump.
	ctx.dash_end_time = -INF
	ctx.coyote_left = 0.0
	var horizontal := ctx.last_dash_direction * ctx.move.dash_speed
	ctx.body.velocity = Vector3(horizontal.x, ctx.move.dash_jump_velocity(), horizontal.z)


func physics_update(_delta: float) -> void:
	machine.transition_to(ctx.air)
