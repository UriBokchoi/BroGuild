class_name SlideState
extends MovementState
## Slide (Ctrl corriendo, mantener; gratis): te deslizas con la velocidad que llevas. En llano
## frena con [code]slide_friction[/code]; la pendiente tira de ti con [code]slide_gravity[/code]
## (acelera cuesta abajo y frena cuesta arriba). Termina al soltar Ctrl, al bajar de
## [code]slide_min_speed[/code] o al dejar el suelo (pasa al aire con coyote time). En la escena
## es comprometido: solo lo interrumpen el dash y el slide-jump.


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
	ctx.body.velocity = velocity.limit_length(ctx.move.slide_max_speed)
	if horizontal_speed() < ctx.move.slide_min_speed:
		machine.transition_to(ctx.ground)


## Aceleración que da la pendiente de normal [param floor_normal]: hacia abajo por la pendiente,
## proporcional a su inclinación (0 en llano).
static func slope_pull(floor_normal: Vector3, slide_gravity: float) -> Vector3:
	return Vector3.DOWN.slide(floor_normal) * slide_gravity
