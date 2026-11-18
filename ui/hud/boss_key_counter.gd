class_name BossKeyCounter
extends HBoxContainer
## Llaves del jefe en el HUD, debajo del oro: un icono y cuántas lleva el jugador de las que hacen
## falta («1/3»), de otro color cuando ya están todas. Solo en niveles con jefe: aparece con el
## primer [signal EventBus.boss_keys_changed] y se va cuando sale el jefe. Estilo: variaciones
## [code]GoldRow[/code], [code]BossKeyLabel[/code] y [code]BossKeyReadyLabel[/code] del Theme global.

## Formato de la cuenta (clave con dos [code]%d[/code]: las que lleva y las que hacen falta).
@export var count_key: StringName = &""

@onready var _label: Label = %BossKeyLabel


func _enter_tree() -> void:
	if not EventBus.boss_keys_changed.is_connected(show_keys):
		EventBus.boss_keys_changed.connect(show_keys)
		EventBus.boss_spawned.connect(_on_boss_spawned)


func _ready() -> void:
	visible = false


## Muestra [param keys] de [param needed].
func show_keys(keys: int, needed: int) -> void:
	_label.text = tr(count_key) % [keys, needed]
	_label.theme_type_variation = &"BossKeyReadyLabel" if keys >= needed else &"BossKeyLabel"
	visible = true


func _on_boss_spawned(_name_key: StringName) -> void:
	visible = false
