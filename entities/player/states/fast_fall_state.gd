class_name FastFallState
extends MovementState
## Caída rápida: Ctrl en el aire. Picado recto al suelo a [code]fast_fall_speed[/code] hasta
## aterrizar; gasta stamina. Al tocar suelo emite [signal slammed] (para la mejora de impacto en
## área y el juice). En la escena comparte acción con el slide, que solo entra en el suelo; es
## comprometida y la cancela el dash.

## Aterrizó de una caída rápida a [param impact_speed] m/s.
signal slammed(impact_speed: float)


func can_enter() -> bool:
	return not ctx.body.is_on_floor() and ctx.stamina.can_spend(ctx.move.fast_fall_cost)


func enter(_previous: State) -> void:
	ctx.stamina.spend(ctx.move.fast_fall_cost)
	_apply_velocity()


func physics_update(_delta: float) -> void:
	if ctx.body.is_on_floor():
		slammed.emit(ctx.move.fast_fall_speed)
		settle()
		return
	_apply_velocity()


func _apply_velocity() -> void:
	ctx.body.velocity = Vector3.DOWN * ctx.move.fast_fall_speed
