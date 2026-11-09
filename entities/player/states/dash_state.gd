class_name DashState
extends MovementState
## Dash: ráfaga corta en la dirección pedida (sin dirección, hacia donde mira la cámara), en el
## suelo o en el aire, donde va recto, sin gravedad. Gasta stamina. En la escena es comprometido
## y cancela cualquier acción (también otro dash). Al terminar, la velocidad horizontal se queda
## en [code]dash_exit_speed[/code] como mucho.

var _direction: Vector3 = Vector3.FORWARD
var _time_left: float = 0.0


func can_enter() -> bool:
	return ctx.stamina.can_spend(ctx.move.dash_cost)


func enter(_previous: State) -> void:
	ctx.stamina.spend(ctx.move.dash_cost)
	var wish := ctx.wish_direction
	_direction = wish.normalized() if wish != Vector3.ZERO else ctx.view_forward
	_time_left = ctx.move.dash_duration
	ctx.last_dash_time = ctx.elapsed
	ctx.last_dash_in_air = not ctx.body.is_on_floor()
	_apply_velocity()


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		_apply_velocity()
		return
	var velocity := ctx.body.velocity
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).limit_length(ctx.move.dash_exit_speed)
	ctx.body.velocity = Vector3(horizontal.x, velocity.y, horizontal.z)
	settle()


func time_left() -> float:
	return maxf(_time_left, 0.0)


func _apply_velocity() -> void:
	ctx.body.velocity = _direction * ctx.move.dash_speed
