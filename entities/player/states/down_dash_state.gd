class_name DownDashState
extends MovementState
## Picado: un segundo Shift en el aire, sin dirección y poco después de un dash hecho en el
## aire, lo convierte en una ráfaga hacia abajo. Gasta stamina además de la del dash. En la
## escena comparte acción con el dash con más prioridad, es comprometido y cancela acciones.
## Termina al pasar su tiempo o al tocar suelo.

var _time_left: float = 0.0


func can_enter() -> bool:
	return (
		not ctx.body.is_on_floor()
		and ctx.wish_direction == Vector3.ZERO
		and ctx.last_dash_in_air
		and ctx.elapsed - ctx.last_dash_time <= ctx.move.down_dash_window
		and ctx.stamina.can_spend(ctx.move.down_dash_cost)
	)


func enter(_previous: State) -> void:
	ctx.stamina.spend(ctx.move.down_dash_cost)
	_time_left = ctx.move.down_dash_duration
	_apply_velocity()


func physics_update(delta: float) -> void:
	_time_left -= delta
	if ctx.body.is_on_floor() or _time_left <= 0.0:
		settle()
		return
	_apply_velocity()


func time_left() -> float:
	return maxf(_time_left, 0.0)


func _apply_velocity() -> void:
	ctx.body.velocity = Vector3.DOWN * ctx.move.down_dash_speed
