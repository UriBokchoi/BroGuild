class_name AnnouncementFeed
extends VBoxContainer
## Textos breves en el HUD ([signal EventBus.announced]): un power-up recogido, una mejora… Cada uno
## sale con un pequeño salto, del color que le toca, se ve [member display_time] segundos y se
## desvanece; si llegan varios, se apilan (como mucho [member max_lines]). No pausa. Estilo:
## variación [code]AnnouncementLabel[/code] del Theme global.

## Segundos a la vista antes de desvanecerse.
@export_range(0.2, 10.0, 0.1, "suffix:s") var display_time: float = 1.6
## Segundos que tarda en desvanecerse.
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_time: float = 0.4
## Textos a la vez como mucho (el más viejo se va).
@export_range(1, 20, 1) var max_lines: int = 5
## Tamaño al salir (luego vuelve al normal).
@export_range(1.0, 3.0, 0.05) var pop_scale: float = 1.35
## Segundos del salto.
@export_range(0.0, 1.0, 0.01, "suffix:s") var pop_time: float = 0.15


func _enter_tree() -> void:
	if not EventBus.announced.is_connected(show_text):
		EventBus.announced.connect(show_text)


## Muestra [param text_key] con [param args] (las claves entre ellos, traducidas) de [param color].
func show_text(text_key: StringName, args: Array, color: Color) -> void:
	var label := Label.new()
	label.theme_type_variation = &"AnnouncementLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = _format(text_key, args)
	label.add_theme_color_override(&"font_color", color)
	label.resized.connect(func() -> void: label.pivot_offset = label.size * 0.5)
	add_child(label)
	while get_child_count() > max_lines:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	label.scale = Vector2.ONE * pop_scale
	var tween := label.create_tween()
	tween.tween_property(label, ^"scale", Vector2.ONE, pop_time)
	tween.tween_interval(display_time)
	tween.tween_property(label, ^"modulate:a", 0.0, fade_time)
	tween.tween_callback(label.queue_free)


## Textos a la vista ahora (ya traducidos).
func get_lines() -> Array[String]:
	var lines: Array[String] = []
	for child: Node in get_children():
		if not child.is_queued_for_deletion():
			lines.append((child as Label).text)
	return lines


func _format(text_key: StringName, args: Array) -> String:
	if args.is_empty():
		return tr(text_key)
	var values: Array = []
	for value: Variant in args:
		if value is StringName:
			var key: StringName = value
			values.append(tr(key))
		else:
			values.append(value)
	return tr(text_key) % values
