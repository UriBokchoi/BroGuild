class_name GoldCounter
extends HBoxContainer
## Oro del jugador en el HUD, debajo de la experiencia: una moneda y la cantidad (sin decimales). Se
## entera por [signal EventBus.player_gold_changed]. Estilo: variaciones [code]GoldRow[/code],
## [code]CoinIcon[/code] y [code]GoldLabel[/code] del Theme global.


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_gold_changed.is_connected(show_gold):
		EventBus.player_gold_changed.connect(show_gold)


## Muestra [param gold].
func show_gold(gold: float) -> void:
	(%GoldLabel as Label).text = str(floori(gold))
