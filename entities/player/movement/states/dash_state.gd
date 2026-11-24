class_name DashState
extends MovementState
## Dash: un impulso corto hacia donde se pide (o hacia la cámara). En el aire va recto y sin gravedad
## y gasta uno de los dashes aéreos. Gasta stamina y puede cortar cualquier acción, incluso otro dash.
##
## Al acabar frena a dash_exit_speed, salvo si se mantiene el slide en el suelo: entonces pasa al
## slide con toda su velocidad. En los dos casos se abre la ventana del dash-jump.

## Estado de slide al que pasa al terminar si se mantiene Ctrl. Vacío: no hay dash → slide.
@export var slide: State

var _direction: Vector3 = Vector3.FORWARD
var _time_left: float = 0.0


func can_enter() -> bool:
	var in_air := not ctx.body.is_on_floor()
	if in_air and ctx.air_dashes_used >= ctx.move.air_dashes:
		return false
	# En el suelo hace falta ir moviéndose: parado o arrancando no hay dash.
	if not in_air and horizontal_speed() < ctx.move.dash_min_speed:
		return false
	return ctx.stamina.can_spend(ctx.move.dash_cost)


func enter(_previous: State) -> void:
	ctx.stamina.spend(ctx.move.dash_cost)
	var wish := ctx.wish_direction
	_direction = wish.normalized() if wish != Vector3.ZERO else ctx.view_forward
	_time_left = ctx.move.dash_duration
	ctx.last_dash_in_air = not ctx.body.is_on_floor()
	ctx.last_dash_direction = _direction
	if ctx.last_dash_in_air:
		ctx.air_dashes_used += 1
	_apply_velocity()


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		_apply_velocity()
		return
	# Al acabar (no si otro dash o el picado lo cancelan) se abre la ventana del dash-jump.
	ctx.dash_end_time = ctx.elapsed
	if slide and ctx.slide_held and slide.can_enter():
		machine.transition_to(slide)
		return
	var velocity := ctx.body.velocity
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).limit_length(ctx.move.dash_exit_speed)
	ctx.body.velocity = Vector3(horizontal.x, velocity.y, horizontal.z)
	settle()


func exit(next: State) -> void:
	# Cortado por el slide cuenta como acabado: dash → slide → dash-jump sigue funcionando.
	if next == slide:
		ctx.dash_end_time = ctx.elapsed


func time_left() -> float:
	return maxf(_time_left, 0.0)


func _apply_velocity() -> void:
	ctx.body.velocity = _direction * ctx.move.dash_speed
