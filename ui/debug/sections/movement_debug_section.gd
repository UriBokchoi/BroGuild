class_name MovementDebugSection
extends DebugSection
## Movimiento del jugador: estado activo, velocidad horizontal y vertical, suelo y coyote time.

var _player: Player
var _state: Label
var _speed: Label
var _vertical_speed: Label
var _on_floor: Label
var _coyote: Label
var _stamina: Label
var _air_jumps: Label
var _sprint: Label


func setup(player: Player) -> void:
	_player = player
	add_title("movement")
	_state = add_value_row("state")
	_speed = add_value_row("speed_xz")
	_vertical_speed = add_value_row("speed_y")
	_on_floor = add_value_row("on_floor")
	_coyote = add_value_row("coyote_left")
	_stamina = add_value_row("stamina")
	_air_jumps = add_value_row("air_jumps_used")
	_sprint = add_value_row("sprint")


func refresh() -> void:
	var velocity := _player.velocity
	_state.text = String(_player.movement.current.name)
	_speed.text = "%.2f m/s" % Vector2(velocity.x, velocity.z).length()
	_vertical_speed.text = "%.2f m/s" % velocity.y
	_on_floor.text = str(_player.is_on_floor())
	_coyote.text = "%.2f s" % _player.context.coyote_left
	_stamina.text = "%.2f / %d" % [_player.stamina.get_charges(), _player.stamina.get_max_charges()]
	_air_jumps.text = "%d / %d" % [_player.context.air_jumps_used, _player.context.move.air_jumps]
	_sprint.text = "%s (%.1f s)" % [_player.context.is_sprinting(), _player.context.sprint_time]
