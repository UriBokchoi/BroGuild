class_name BossBar
extends PanelContainer
## El jefe en el HUD, arriba en el centro: su nombre, su vida y lo que grita (se ve un rato). Aparece
## al salir ([signal EventBus.boss_spawned]) y se va al vencerlo ([signal EventBus.boss_defeated]).
## Estilo: variaciones [code]BossBarFrame[/code], [code]BossNameLabel[/code],
## [code]BossHealthBar[/code] y [code]BossShoutLabel[/code] del Theme global.

## Segundos que se ve cada grito.
@export_range(0.1, 10.0, 0.1, "suffix:s") var shout_time: float = 2.5

var _shout_left: float = 0.0

@onready var _name: Label = %BossName
@onready var _health: ProgressBar = %BossHealth
@onready var _shout: Label = %BossShout


func _enter_tree() -> void:
	if not EventBus.boss_spawned.is_connected(show_boss):
		EventBus.boss_spawned.connect(show_boss)
		EventBus.boss_health_changed.connect(show_health)
		EventBus.boss_shouted.connect(show_shout)
		EventBus.boss_defeated.connect(_on_boss_defeated)


func _ready() -> void:
	visible = false
	_shout.visible = false
	_health.show_percentage = false
	_health.step = 0.0
	set_process(false)


func _process(delta: float) -> void:
	_shout_left -= delta
	if _shout_left <= 0.0:
		_shout.visible = false
		set_process(false)


## Muestra al jefe [param name_key] (clave de su nombre).
func show_boss(name_key: StringName) -> void:
	_name.text = name_key
	visible = true


## Muestra [param current] de [param maximum] de vida.
func show_health(current: float, maximum: float) -> void:
	_health.max_value = maximum
	_health.value = current


## Muestra el grito [param text_key] durante [member shout_time] segundos.
func show_shout(text_key: StringName) -> void:
	_shout.text = text_key
	_shout.visible = true
	_shout_left = shout_time
	set_process(true)


## Texto del grito que se ve ahora (vacío si no hay; sin traducir).
func get_shout() -> String:
	return _shout.text if _shout.visible else ""


func _on_boss_defeated(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	visible = false
