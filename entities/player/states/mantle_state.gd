class_name MantleState
extends MovementState
## Mantle: Espacio delante de un borde a media altura (en el suelo o en el aire) lo sube. Primero
## sube en vertical hasta pasar el borde, luego avanza hacia dentro y sale con un pico de
## velocidad ([code]mantle_exit_speed[/code]); con Ctrl mantenido sale deslizando. Gratis. En la
## escena va por encima de todo lo demás que hace Espacio y es comprometido (lo cancela el dash).

## Margen de seguridad sobre lo que debería tardar, por si algo lo atasca.
const TIMEOUT_MARGIN := 0.2

## Estado de slide al que sale si se mantiene Ctrl.
@export var slide: State

var _ledge: LedgeSensor.Ledge
var _climbing: bool = false
var _time_left: float = 0.0


func can_enter() -> bool:
	return _find_ledge() != null


func enter(_previous: State) -> void:
	_ledge = _find_ledge()
	_climbing = true
	ctx.coyote_left = 0.0
	var climb_time := maxf(_ledge.height, 0.0) / ctx.move.mantle_climb_speed
	var forward_time := ctx.move.mantle_reach / ctx.move.mantle_exit_speed
	_time_left = climb_time + forward_time + TIMEOUT_MARGIN
	ctx.body.velocity = Vector3.UP * ctx.move.mantle_climb_speed


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _climbing and ctx.body.global_position.y >= _ledge.target.y:
		_climbing = false
	if _time_left <= 0.0 or (not _climbing and _past_target()):
		_finish()
		return
	if _climbing:
		ctx.body.velocity = Vector3.UP * ctx.move.mantle_climb_speed
		return
	# Ya encima: avanza con la gravedad puesta, para acabar pisando el borde.
	var forward := _ledge.direction * ctx.move.mantle_exit_speed
	ctx.body.velocity = Vector3(forward.x, minf(ctx.body.velocity.y, 0.0), forward.z)
	apply_gravity(delta)


func time_left() -> float:
	return maxf(_time_left, 0.0)


func _finish() -> void:
	var boost := _ledge.direction * ctx.move.mantle_exit_speed
	ctx.body.velocity = Vector3(boost.x, ctx.body.velocity.y, boost.z)
	if slide and ctx.slide_held and slide.can_enter():
		machine.transition_to(slide)
		return
	settle()


func _past_target() -> bool:
	return (ctx.body.global_position - _ledge.target).dot(_ledge.direction) >= 0.0


func _find_ledge() -> LedgeSensor.Ledge:
	var wish := ctx.wish_direction
	return ctx.find_ledge(wish if wish != Vector3.ZERO else ctx.view_forward)
