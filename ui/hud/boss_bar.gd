class_name BossBar
extends PanelContainer
## La barra de un jefe, arriba en el centro: nombre a la izquierda, vida en números a la derecha
## («4530 / 5000») y una barra fina. La del jefe y la del miniboss (mini_boss) van una bajo la otra
## y se van al vencerlos, al ganar la partida o al pasar de tier.

## Clave del texto de su vida (con dos [code]%d[/code]: la que le queda y la máxima).
@export var value_key: StringName = &"HUD_HEALTH_VALUE"
## Muestra al miniboss en vez de al jefe del nivel.
@export var mini_boss: bool = false

@onready var _name: Label = %BossName
@onready var _value: Label = %BossValue
@onready var _health: ProgressBar = %BossHealth


func _enter_tree() -> void:
	if EventBus.run_won.is_connected(_on_run_won):
		return
	# Al ganar la partida se van las dos (el miniboss puede seguir vivo tras vencer al jefe).
	EventBus.run_won.connect(_on_run_won)
	EventBus.stage_started.connect(_on_stage_started)
	if mini_boss:
		EventBus.mini_boss_spawned.connect(show_boss)
		EventBus.mini_boss_health_changed.connect(show_health)
		EventBus.mini_boss_defeated.connect(_on_mini_boss_defeated)
	else:
		EventBus.boss_spawned.connect(show_boss)
		EventBus.boss_health_changed.connect(show_health)
		EventBus.boss_defeated.connect(_on_boss_defeated)


func _ready() -> void:
	visible = false
	_health.show_percentage = false
	_health.step = 0.0


## Muestra al jefe [param name_key] (clave de su nombre).
func show_boss(name_key: StringName) -> void:
	_name.text = name_key
	visible = true


## Muestra [param current] de [param maximum] de vida.
func show_health(current: float, maximum: float) -> void:
	_health.max_value = maximum
	_health.value = current
	# Redondeada hacia arriba: mientras esté vivo no marca 0.
	_value.text = tr(value_key) % [ceili(current), roundi(maximum)]


## Los números de su vida que se ven ahora.
func get_value_text() -> String:
	return _value.text


func _on_boss_defeated(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	visible = false


func _on_mini_boss_defeated(_name_key: StringName) -> void:
	visible = false


func _on_run_won(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	visible = false


func _on_stage_started(_name_key: StringName, _index: int, _count: int) -> void:
	visible = false
