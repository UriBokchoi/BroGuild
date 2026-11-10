class_name AirState
extends MovementState
## En el aire sin ninguna acción en curso: cae con la gravedad, con control aéreo, hasta tocar
## suelo. Mientras, se agota el coyote time y sigue contando el sprint. Si aterriza con Ctrl
## mantenido y con velocidad, sigue deslizando sin perder el impulso (como en Deadlock).

## Estado de slide al que pasa al aterrizar con Ctrl mantenido. Vacío: siempre a Suelo.
@export var slide: State


func physics_update(delta: float) -> void:
	if ctx.body.is_on_floor():
		if slide and ctx.slide_held and slide.can_enter():
			machine.transition_to(slide)
		else:
			machine.transition_to(ctx.ground)
		return
	ctx.coyote_left = maxf(ctx.coyote_left - delta, 0.0)
	track_sprint(delta)
	apply_gravity(delta)
	apply_air_control(delta)
