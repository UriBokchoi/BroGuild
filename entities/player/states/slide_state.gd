class_name SlideState
extends MovementState
## Slide (Ctrl corriendo, mantener; gratis): te deslizas con la velocidad que llevas. En llano
## frena con [code]slide_friction[/code]; la pendiente tira de ti con [code]slide_gravity[/code]
## (acelera cuesta abajo y frena cuesta arriba). Con WASD se curva hacia la dirección pedida, a
## [code]slide_turn_speed[/code] como mucho y sin perder velocidad (como en Deadlock). Termina al
## soltar Ctrl, al bajar de [code]slide_min_speed[/code] o al dejar el suelo (pasa al aire con
## coyote time). En la escena es comprometido: solo lo interrumpen el dash y el slide-jump.


func can_enter() -> bool:
	return ctx.body.is_on_floor() and horizontal_speed() >= ctx.move.slide_min_speed


func physics_update(delta: float) -> void:
	if not ctx.body.is_on_floor():
		ctx.coyote_left = ctx.move.coyote_time
		machine.transition_to(ctx.air)
		return
	if not ctx.slide_held:
		machine.transition_to(ctx.ground)
		return
	var velocity := ctx.body.velocity
	velocity += slope_pull(ctx.body.get_floor_normal(), ctx.move.slide_gravity) * delta
	velocity = velocity.move_toward(Vector3.ZERO, ctx.move.slide_friction * delta)
	velocity = steer(velocity, ctx.wish_direction, ctx.move.slide_turn_speed * delta)
	ctx.body.velocity = velocity.limit_length(ctx.move.slide_max_speed)
	if horizontal_speed() < ctx.move.slide_min_speed:
		machine.transition_to(ctx.ground)


## Aceleración que da la pendiente de normal [param floor_normal]: hacia abajo por la pendiente,
## proporcional a su inclinación (0 en llano).
static func slope_pull(floor_normal: Vector3, slide_gravity: float) -> Vector3:
	return Vector3.DOWN.slide(floor_normal) * slide_gravity


## Gira la parte horizontal de [param velocity] hacia [param wish] como mucho [param max_turn]
## radianes, sin cambiar su rapidez ni la parte vertical. Sin dirección pedida, no gira.
static func steer(velocity: Vector3, wish: Vector3, max_turn: float) -> Vector3:
	var horizontal := Vector2(velocity.x, velocity.z)
	var wanted := Vector2(wish.x, wish.z)
	if horizontal.is_zero_approx() or wanted.is_zero_approx():
		return velocity
	var turn := clampf(horizontal.angle_to(wanted), -max_turn, max_turn)
	var turned := horizontal.rotated(turn)
	return Vector3(turned.x, velocity.y, turned.y)
