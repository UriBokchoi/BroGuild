class_name StageLabel
extends Label
## La fase en juego en un nivel con tiers («Tier 2 · Otoño»), pequeña bajo la dificultad. Se entera
## por EventBus.stage_started; en un nivel sin tiers no sale.


func _enter_tree() -> void:
	if not EventBus.stage_started.is_connected(_on_stage_started):
		EventBus.stage_started.connect(_on_stage_started)


func _ready() -> void:
	visible = false


func _on_stage_started(name_key: StringName, _index: int, _count: int) -> void:
	text = name_key
	visible = true
