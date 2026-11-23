class_name BossBar
extends PanelContainer
## La barra de un jefe en el HUD, arriba en el centro: su nombre a la izquierda, su vida en números
## a la derecha («4530 / 5000») y una barra fina debajo. La del jefe del nivel aparece al salir
## ([signal EventBus.boss_spawned]) y se va al vencerlo ([signal EventBus.boss_defeated]); la del
## miniboss ([member mini_boss]) va con sus propias señales y también se va si se pasa el nivel. Las
## dos van en una columna, una bajo la otra. Estilo: variaciones [code]BossBarPanel[/code],
## [code]BossNameLabel[/code], [code]BossValueLabel[/code] y [code]BossHealthBar[/code] del Theme
## global (las del miniboss, más pequeñas y en verde, se ponen en el HUD).

## Clave del texto de su vida (con dos [code]%d[/code]: la que le queda y la máxima).
@export var value_key: StringName = &"HUD_HEALTH_VALUE"
## Muestra al miniboss en vez de al jefe del nivel.
@export var mini_boss: bool = false

@onready var _name: Label = %BossName
@onready var _value: Label = %BossValue
@onready var _health: ProgressBar = %BossHealth


func _enter_tree() -> void:
	if EventBus.boss_defeated.is_connected(_on_boss_defeated):
		return
	EventBus.boss_defeated.connect(_on_boss_defeated)
	if mini_boss:
		EventBus.mini_boss_spawned.connect(show_boss)
		EventBus.mini_boss_health_changed.connect(show_health)
		EventBus.mini_boss_defeated.connect(_on_mini_boss_defeated)
	else:
		EventBus.boss_spawned.connect(show_boss)
		EventBus.boss_health_changed.connect(show_health)


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
