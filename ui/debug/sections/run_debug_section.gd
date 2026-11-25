class_name RunDebugSection
extends DebugSection
## Ayudas para probar la partida: «god mode» hace inmortal al jugador (los golpes le llegan, pero no
## le quitan vida), para recorrer los tiers o probar jefes sin morir.

var _health: HealthComponent


func setup(player: Player) -> void:
	_health = player.health
	add_title("run")
	var god := CheckButton.new()
	god.text = "god mode"
	god.focus_mode = Control.FOCUS_NONE
	god.button_pressed = _health.immortal
	god.toggled.connect(set_god_mode)
	add_child(god)


## Hace al jugador inmortal (o deja de hacerlo).
func set_god_mode(on: bool) -> void:
	_health.immortal = on
