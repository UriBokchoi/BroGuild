class_name GoldCounter
extends HBoxContainer
## Oro del jugador en el HUD, debajo de la experiencia: una moneda y la cantidad (sin decimales). Se
## entera por [signal EventBus.player_gold_changed]; al ganar oro, la cantidad da un salto. Estilo:
## variaciones [code]GoldRow[/code], [code]CoinIcon[/code] y [code]GoldLabel[/code] del Theme global.

var _gold: float = -1.0


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.player_gold_changed.is_connected(show_gold):
		EventBus.player_gold_changed.connect(show_gold)


## Muestra [param gold].
func show_gold(gold: float) -> void:
	var label := %GoldLabel as Label
	var shown := str(floori(gold))
	# Salta al ganar (no al gastar ni con el primer aviso).
	if gold > _gold and _gold >= 0.0 and shown != label.text:
		UiMotion.pop(label)
	_gold = gold
	label.text = shown
