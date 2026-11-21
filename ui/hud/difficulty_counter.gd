class_name DifficultyCounter
extends HBoxContainer
## Dificultad en el HUD, arriba a la derecha: una calavera y su valor con un decimal. Se entera por
## [signal EventBus.difficulty_changed]. Estilo: variación [code]DifficultyLabel[/code] del Theme
## global.


func _enter_tree() -> void:
	# En _enter_tree para no perder el primer aviso, que llega en el _ready del jugador.
	if not EventBus.difficulty_changed.is_connected(show_difficulty):
		EventBus.difficulty_changed.connect(show_difficulty)


## Muestra [param difficulty].
func show_difficulty(difficulty: float) -> void:
	(%DifficultyLabel as Label).text = StatFormat.fixed(difficulty, 1)
