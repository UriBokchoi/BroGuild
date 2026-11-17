class_name SlotPanel
extends PanelContainer
## Los rodillos de la tragaperras en el HUD, sin pausar el juego: al girar
## ([signal EventBus.slot_spun]) cada rodillo cambia de símbolo hasta que se para, uno tras otro,
## en lo que salió; luego muestra el resultado ([signal EventBus.slot_resolved]) un rato y se oculta.
## Si no hay oro, solo muestra el aviso. Estilo: variaciones [code]SlotPanel[/code],
## [code]SlotReel[/code], [code]SlotResultLabel[/code] y [code]SlotJackpotLabel[/code].

## Segundos entre cambios de símbolo mientras gira un rodillo.
@export_range(0.01, 0.5, 0.01, "suffix:s") var flicker_interval: float = 0.06
## Segundos que se queda el resultado a la vista.
@export_range(0.1, 10.0, 0.1, "suffix:s") var linger: float = 2.5
## Lado de cada rodillo.
@export_range(16.0, 256.0, 1.0, "suffix:px") var reel_size: float = 72.0

var _data: SlotMachineData
var _results: Array[SlotSymbol] = []
var _elapsed: float = 0.0
var _flicker: float = 0.0
var _hide_left: float = 0.0
## Azar de los símbolos que pasan (solo visual).
var _rng: RandomNumberGenerator

@onready var _reels: HBoxContainer = %Reels
@onready var _result: Label = %SlotResult


func _enter_tree() -> void:
	if not EventBus.slot_spun.is_connected(show_spin):
		EventBus.slot_spun.connect(show_spin)
		EventBus.slot_resolved.connect(show_result)


func _ready() -> void:
	_rng = Rng.stream(Rng.Stream.COSMETIC)
	visible = false
	set_process(false)


## Empieza a girar los rodillos de [param data] hasta parar en [param results].
func show_spin(data: SlotMachineData, results: Array[SlotSymbol]) -> void:
	_data = data
	_results = results
	_elapsed = 0.0
	_flicker = 0.0
	_hide_left = 0.0
	_build_reels(results.size())
	_reels.visible = true
	_result.visible = false
	visible = true
	set_process(true)


## Muestra el resultado [param text_key] (con [param value] si lleva [code]%d[/code]).
func show_result(text_key: StringName, value: float, jackpot: bool) -> void:
	var text := tr(text_key)
	_result.text = text % roundi(value) if text.contains("%d") else text
	_result.theme_type_variation = &"SlotJackpotLabel" if jackpot else &"SlotResultLabel"
	_result.visible = true
	if _data == null:
		# Sin tirada (no había oro): solo el aviso.
		_reels.visible = false
	visible = true
	_hide_left = linger
	set_process(true)


## ¿Sigue girando algún rodillo?
func is_spinning() -> bool:
	return _data != null and _elapsed < _data.total_time()


## Símbolos que se ven ahora en los rodillos.
func get_shown() -> Array[Texture2D]:
	var shown: Array[Texture2D] = []
	for reel: Node in _reels.get_children():
		shown.append((reel.get_child(0) as TextureRect).texture)
	return shown


func _process(delta: float) -> void:
	if _data:
		_spin(delta)
	if _hide_left > 0.0:
		_hide_left -= delta
		if _hide_left <= 0.0:
			visible = false
			_data = null
			set_process(false)


func _spin(delta: float) -> void:
	_elapsed += delta
	_flicker -= delta
	var flicker := _flicker <= 0.0
	if flicker:
		_flicker = flicker_interval
	for index: int in _results.size():
		var icon := (_reels.get_child(index).get_child(0) as TextureRect)
		if _elapsed >= _data.spin_time + _data.reel_delay * index:
			icon.texture = _results[index].icon
		elif flicker:
			var symbol := _data.symbols.pick(_rng) as SlotSymbol
			icon.texture = symbol.icon


func _build_reels(count: int) -> void:
	while _reels.get_child_count() < count:
		var reel := PanelContainer.new()
		reel.theme_type_variation = &"SlotReel"
		reel.custom_minimum_size = Vector2(reel_size, reel_size)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reel.add_child(icon)
		_reels.add_child(reel)
	for index: int in _reels.get_child_count():
		(_reels.get_child(index) as Control).visible = index < count
