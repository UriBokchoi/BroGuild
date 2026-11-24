class_name OptionsPanel
extends PanelContainer
## Opciones básicas: volumen de cada bus, pantalla completa, tamaño de la ventana, VSync, límite de
## FPS y temblor de pantalla. El volumen y el temblor se aplican al momento (para oírlo o notarlo); las de pantalla
## quedan pendientes hasta «Aplicar», que las aplica y las guarda. «Volver» o Esc guardan el volumen
## y el temblor, descartan lo de pantalla sin aplicar y cierran. Trabaja sobre
## [code]Save.settings[/code]. Lo abren la pausa y el menú principal. Ejecutado dentro del editor, la
## ventana no se puede cambiar: lo avisa y desactiva esas opciones.

## Se cerró (ya guardado).
signal closed

## Qué buses tienen volumen y qué tamaños de ventana se ofrecen.
@export var data: SettingsData

var _sliders: Dictionary[StringName, HSlider] = {}
var _value_labels: Dictionary[StringName, Label] = {}
var _resolutions: Array[Vector2i] = []
## Opciones de pantalla elegidas y aún sin aplicar.
var _pending: GameSettings

@onready var _volumes: VBoxContainer = %Volumes
@onready var _fullscreen: CheckButton = %Fullscreen
@onready var _resolution: OptionButton = %Resolution
@onready var _vsync: CheckButton = %VSync
@onready var _fps_limit: OptionButton = %FpsLimit
@onready var _shake: HSlider = %ScreenShake
@onready var _shake_value: Label = %ScreenShakeValue
@onready var _window_note: Label = %WindowNote
@onready var _apply: Button = %Apply
@onready var _back: Button = %Back


func _ready() -> void:
	for bus: StringName in data.volume_buses:
		_add_volume_row(bus)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	_resolution.item_selected.connect(_on_resolution_selected)
	_vsync.toggled.connect(_on_vsync_toggled)
	for limit: int in data.fps_limits:
		_fps_limit.add_item(str(limit) if limit > 0 else tr(&"OPTIONS_FPS_UNLIMITED"))
	_fps_limit.item_selected.connect(_on_fps_limit_selected)
	_shake.value_changed.connect(_on_shake_changed)
	_apply.pressed.connect(apply)
	_back.pressed.connect(close)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra las opciones actuales y deja el foco en «Volver».
func open() -> void:
	_pending = Save.settings.copy()
	_show_settings()
	UiMotion.reveal(self)
	_back.grab_focus()


## Aplica y guarda las opciones de pantalla pendientes.
func apply() -> void:
	Save.settings.take_display(_pending)
	Save.settings.apply_display(get_window())
	Save.save_settings()
	_refresh_apply()


## Guarda el volumen, descarta lo de pantalla sin aplicar y se cierra.
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
	for bus: StringName in _sliders:
		var volumes := Save.settings.volumes
		_sliders[bus].set_value_no_signal(volumes[bus] if volumes.has(bus) else 0.0)
		_show_volume(bus)
	var can_change := GameSettings.can_change_window()
	_window_note.visible = not can_change
	_fullscreen.disabled = not can_change
	_shake.set_value_no_signal(Save.settings.screen_shake)
	_show_shake()
	_fullscreen.set_pressed_no_signal(_pending.fullscreen)
	_vsync.set_pressed_no_signal(_pending.vsync)
	_fps_limit.select(data.fps_limits.find(_pending.fps_limit))
	_fill_resolutions()
	_refresh_apply()


## Lista los tamaños que caben en la pantalla (sin la barra de tareas) y el que hay ahora, si no está
## entre ellos.
func _fill_resolutions() -> void:
	var usable := DisplayServer.screen_get_usable_rect().size
	var current := shown_resolution()
	_resolutions.clear()
	for option: Vector2i in data.resolutions:
		# Sin pantalla (headless), el área es cero: se ofrecen todos.
		if usable == Vector2i.ZERO or (option.x <= usable.x and option.y <= usable.y):
			_resolutions.append(option)
	if not _resolutions.has(current):
		_resolutions.push_front(current)
	_resolution.clear()
	for option: Vector2i in _resolutions:
		_resolution.add_item(tr(&"OPTIONS_RESOLUTION_VALUE") % [option.x, option.y])
	_resolution.select(_resolutions.find(current))
	_refresh_resolution()


## El tamaño que enseña la lista: en pantalla completa, el de la pantalla (el de verdad, aunque haya
## un tamaño de ventana guardado); en ventana, el elegido o, si no hay, el de la ventana ahora.
func shown_resolution() -> Vector2i:
	if _pending.fullscreen:
		return DisplayServer.screen_get_size(get_window().current_screen)
	if _pending.resolution != Vector2i.ZERO:
		return _pending.resolution
	return get_window().size


## Sin tamaño de ventana en pantalla completa ni dentro del editor.
func _refresh_resolution() -> void:
	_resolution.disabled = _pending.fullscreen or not GameSettings.can_change_window()


func _refresh_apply() -> void:
	_apply.disabled = not _pending.display_differs(Save.settings)


func _show_volume(bus: StringName) -> void:
	_value_labels[bus].text = tr(&"OPTIONS_VOLUME_VALUE") % roundi(_sliders[bus].value * 100.0)


func _on_volume_changed(value: float, bus: StringName) -> void:
	Save.settings.volumes[bus] = value
	_show_volume(bus)
	Save.settings.apply_audio()


func _on_fullscreen_toggled(on: bool) -> void:
	_pending.fullscreen = on
	# Cambia el tamaño que se enseña (el de la pantalla o el de la ventana).
	_fill_resolutions()
	_refresh_apply()


func _on_resolution_selected(index: int) -> void:
	_pending.resolution = _resolutions[index]
	_refresh_apply()


func _show_shake() -> void:
	_shake_value.text = tr(&"OPTIONS_VOLUME_VALUE") % roundi(_shake.value * 100.0)


func _on_shake_changed(value: float) -> void:
	Save.settings.screen_shake = value
	_show_shake()


func _on_vsync_toggled(on: bool) -> void:
	_pending.vsync = on
	_refresh_apply()


func _on_fps_limit_selected(index: int) -> void:
	_pending.fps_limit = data.fps_limits[index]
	_refresh_apply()
