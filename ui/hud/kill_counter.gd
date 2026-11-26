class_name KillCounter
extends HBoxContainer
## Enemigos derrotados en la partida, en el HUD, encima de la dificultad: un icono y el número. Cuenta
## cada [signal EventBus.enemy_died] (los que se hunden al cambiar de mapa no mueren: no cuentan).

var _kills: int = 0


func _enter_tree() -> void:
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)


func _ready() -> void:
	show_kills(_kills)


## Muestra [param kills].
func show_kills(kills: int) -> void:
	_kills = kills
	(%KillsLabel as Label).text = str(kills)


## Los que lleva.
func get_kills() -> int:
	return _kills


func _on_enemy_died(_enemy: Enemy) -> void:
	show_kills(_kills + 1)
