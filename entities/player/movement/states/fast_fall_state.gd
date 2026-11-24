class_name FastFallState
extends MovementState
## Caída rápida: Ctrl dos veces seguidas en el aire. Bajas en picado hasta el suelo y gastas stamina;
## al aterrizar avisa (slammed), para la explosión de su mejora y el temblor.

## Aterrizó de una caída rápida a [param impact_speed] m/s.
signal slammed(impact_speed: float)


func can_enter() -> bool:
	return (
		not ctx.body.is_on_floor()
		and ctx.is_double_tap(trigger_action, ctx.move.fast_fall_double_tap_window)
		and ctx.stamina.can_spend(ctx.move.fast_fall_cost)
	)


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
