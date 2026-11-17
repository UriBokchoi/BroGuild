class_name OptionsPanel
extends PanelContainer
## Opciones básicas: volumen de cada bus, pantalla completa, tamaño de la ventana y VSync. Cada
## cambio se aplica al momento sobre [code]Save.settings[/code] y al cerrar se guarda. Lo abre la
## pausa (y, más adelante, el menú principal). Esc o «Volver» lo cierran.

## Se cerró (ya guardado).
signal closed

## Qué buses tienen volumen y qué tamaños de ventana se ofrecen.
@export var data: SettingsData

var _sliders: Dictionary[StringName, HSlider] = {}
var _value_labels: Dictionary[StringName, Label] = {}
var _resolutions: Array[Vector2i] = []

@onready var _volumes: VBoxContainer = %Volumes
@onready var _fullscreen: CheckButton = %Fullscreen
@onready var _resolution: OptionButton = %Resolution
@onready var _vsync: CheckButton = %VSync
@onready var _back: Button = %Back


func _ready() -> void:
	for bus: StringName in data.volume_buses:
		_add_volume_row(bus)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	_resolution.item_selected.connect(_on_resolution_selected)
	_vsync.toggled.connect(_on_vsync_toggled)
	_back.pressed.connect(close)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra las opciones actuales y deja el foco en «Volver».
func open() -> void:
	_show_settings()
	visible = true
	_back.grab_focus()


## Guarda y se cierra.
func close() -> void:
	if not visible:
		return
	visible = false
	Save.save_settings()
	closed.emit()


## Deslizador de volumen de [param bus] (o [code]null[/code]).
func get_volume_slider(bus: StringName) -> HSlider:
	return _sliders[bus] if _sliders.has(bus) else null


## Tamaños de ventana que ofrece, en el orden de la lista.
func get_resolutions() -> Array[Vector2i]:
	return _resolutions.duplicate()


func _add_volume_row(bus: StringName) -> void:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"OptionsRow"
	var name_label := Label.new()
	name_label.text = "OPTIONS_VOLUME_%s" % String(bus).to_upper()
	name_label.theme_type_variation = &"StatNameLabel"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = data.volume_step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := Label.new()
	value_label.theme_type_variation = &"OptionsValueLabel"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	_sliders[bus] = slider
	_value_labels[bus] = value_label
	_volumes.add_child(row)


func _show_settings() -> void:
	var settings := Save.settings
	for bus: StringName in _sliders:
		var slider := _sliders[bus]
		slider.set_value_no_signal(settings.volumes[bus] if settings.volumes.has(bus) else 0.0)
		_show_volume(bus)
	_fullscreen.set_pressed_no_signal(settings.fullscreen)
	_vsync.set_pressed_no_signal(settings.vsync)
	_fill_resolutions()


## Lista los tamaños que caben en la pantalla y el de la ventana ahora, si no está entre ellos.
func _fill_resolutions() -> void:
	var screen := DisplayServer.screen_get_size()
	var current := Save.settings.resolution
	if current == Vector2i.ZERO:
		current = get_window().size
	_resolutions.clear()
	for option: Vector2i in data.resolutions:
		# Sin pantalla (headless), screen es cero: se ofrecen todos.
		if screen == Vector2i.ZERO or (option.x <= screen.x and option.y <= screen.y):
			_resolutions.append(option)
	if not _resolutions.has(current):
		_resolutions.push_front(current)
	_resolution.clear()
	for option: Vector2i in _resolutions:
		_resolution.add_item(tr(&"OPTIONS_RESOLUTION_VALUE") % [option.x, option.y])
	_resolution.select(_resolutions.find(current))
	_resolution.disabled = Save.settings.fullscreen


func _show_volume(bus: StringName) -> void:
	_value_labels[bus].text = tr(&"OPTIONS_VOLUME_VALUE") % roundi(_sliders[bus].value * 100.0)


func _on_volume_changed(value: float, bus: StringName) -> void:
	Save.settings.volumes[bus] = value
	_show_volume(bus)
	Save.settings.apply_audio()


func _on_fullscreen_toggled(on: bool) -> void:
	Save.settings.fullscreen = on
	_resolution.disabled = on
	Save.settings.apply_display(get_window())


func _on_resolution_selected(index: int) -> void:
	Save.settings.resolution = _resolutions[index]
	Save.settings.apply_display(get_window())


func _on_vsync_toggled(on: bool) -> void:
	Save.settings.vsync = on
	Save.settings.apply_display(get_window())
