class_name LevelIntro
extends VBoxContainer
## Mensajes de bienvenida al empezar un nivel ([signal EventBus.level_intro]): el primero en grande y
## los demás debajo; se ven [member display_time] segundos y se desvanecen. Estilo: variaciones
## [code]IntroTitleLabel[/code] e [code]IntroLineLabel[/code] del Theme global.

## Segundos a la vista antes de desvanecerse.
@export_range(0.5, 20.0, 0.1, "suffix:s") var display_time: float = 3.5
## Segundos que tarda en desvanecerse.
@export_range(0.0, 5.0, 0.1, "suffix:s") var fade_time: float = 1.0

var _fade: Tween


func _enter_tree() -> void:
	# En _enter_tree: el nivel avisa en su _ready.
	if not EventBus.level_intro.is_connected(show_intro):
		EventBus.level_intro.connect(show_intro)


func _ready() -> void:
	visible = false


## Muestra [param text_keys] (el primero, grande) y luego los desvanece.
func show_intro(text_keys: Array[StringName]) -> void:
	for child: Node in get_children():
		child.queue_free()
	for index: int in text_keys.size():
		var label := Label.new()
		label.text = text_keys[index]
		label.theme_type_variation = &"IntroTitleLabel" if index == 0 else &"IntroLineLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	visible = true
	modulate.a = 1.0
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_interval(display_time)
	_fade.tween_property(self, ^"modulate:a", 0.0, fade_time)
	_fade.tween_callback(hide)


## Textos que se muestran ahora (sin traducir).
func get_lines() -> Array[String]:
	var lines: Array[String] = []
	for child: Node in get_children():
		if not child.is_queued_for_deletion():
			lines.append((child as Label).text)
	return lines
