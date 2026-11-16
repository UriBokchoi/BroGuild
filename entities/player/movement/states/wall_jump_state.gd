class_name WallJumpState
extends MovementState
## Salto en pared, al estilo de Deadlock: en el aire junto a una pared, Espacio te impulsa hacia
## arriba y hacia donde pides, separándote de la pared (si pides hacia la pared, rebotas). Sales
## al menos a [code]wall_jump_speed[/code]; si ibas más rápido, conservas tu velocidad. El primero
## es gratis; los encadenados sin tocar suelo gastan [code]wall_jump_chain_cost[/code]. En la
## escena va por encima del dash-jump y del doble salto. Pasa al aire en el mismo tick.


func can_enter() -> bool:
	if ctx.body.is_on_floor() or ctx.wall_normal() == Vector3.ZERO:
		return false
	return ctx.stamina.can_spend(cost(ctx.wall_jumps_chained, ctx.move.wall_jump_chain_cost))


func enter(_previous: State) -> void:
	ctx.stamina.spend(cost(ctx.wall_jumps_chained, ctx.move.wall_jump_chain_cost))
	ctx.wall_jumps_chained += 1
	ctx.coyote_left = 0.0
	var direction := kick_direction(ctx.wish_direction, ctx.wall_normal())
	var speed := maxf(horizontal_speed(), ctx.move.wall_jump_speed)
	var horizontal := direction * speed
	ctx.body.velocity = Vector3(horizontal.x, ctx.move.wall_jump_velocity(), horizontal.z)


func physics_update(_delta: float) -> void:
	machine.transition_to(ctx.air)


## Cargas que cuesta el salto en pared número [param chained] + 1 (el primero es gratis).
static func cost(chained: int, chain_cost: float) -> float:
	return 0.0 if chained == 0 else chain_cost


## Dirección horizontal de salida: la pedida (rebotada si apunta a la pared) más la normal de la
## pared, para separarse siempre de ella. Sin dirección pedida, recto hacia fuera.
static func kick_direction(wish: Vector3, wall_normal: Vector3) -> Vector3:
	var flat_wish := Vector3(wish.x, 0.0, wish.z)
	if flat_wish.is_zero_approx():
		return wall_normal
	if flat_wish.dot(wall_normal) < 0.0:
		flat_wish = flat_wish.bounce(wall_normal)
	return (flat_wish.normalized() + wall_normal).normalized()
