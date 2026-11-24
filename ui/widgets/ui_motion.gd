class_name UiMotion
extends RefCounted
## Movimientos de la interfaz con tweens: un salto (un contador que sube), una aparición (un panel
## que se abre), un botón que crece con el ratón y una barra que llega a su valor sin saltos. Los
## tiempos viven en data/ui/motion.tres. Siguen con el juego en pausa.

const DATA: UiMotionData = preload("res://data/ui/motion.tres")
## Metadato donde cada control guarda su tween de tamaño en marcha.
const TWEEN_META := &"ui_motion_tween"


## Salta: crece hasta [member UiMotionData.pop_scale] y vuelve a su tamaño, desde su centro.
static func pop(control: Control) -> Tween:
	var tween := _restart(control)
	control.scale = Vector2.ONE * DATA.pop_scale
	tween.tween_property(control, ^"scale", Vector2.ONE, DATA.pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Aparece: de transparente y algo más pequeño a como es, desde su centro.
static func appear(control: Control) -> Tween:
	var tween := _restart(control)
	control.scale = Vector2.ONE * DATA.appear_scale
	control.modulate.a = 0.0
	tween.set_parallel()
	tween.tween_property(control, ^"scale", Vector2.ONE, DATA.appear_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, ^"modulate:a", 1.0, DATA.appear_time)
	return tween


## Lo muestra con [method appear] si estaba oculto (si ya se veía, no hace nada).
static func reveal(control: Control) -> void:
	if control.visible:
		return
	control.visible = true
	if control.is_inside_tree():
		appear(control)


## Lleva el tamaño de [param control] a [param target] (1 = normal) en
## [member UiMotionData.hover_time]: un botón con el ratón encima, pulsado o soltado.
static func scale_to(control: Control, target: float) -> Tween:
	var tween := _restart(control)
	tween.tween_property(control, ^"scale", Vector2.ONE * target, DATA.hover_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


## Lleva [param bar] a [param value] en [member UiMotionData.bar_time] (sin saltos). Devuelve el tween.
static func slide(bar: Range, value: float) -> Tween:
	var tween := bar.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bar, ^"value", value, DATA.bar_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


## Corta el tween de tamaño de [param control] (si lleva uno), centra su pivote y le crea otro.
static func _restart(control: Control) -> Tween:
	if control.has_meta(TWEEN_META):
		var previous := control.get_meta(TWEEN_META) as Tween
		if previous and previous.is_valid():
			previous.kill()
	# Recién creado aún no tiene tamaño: su mínimo da el centro.
	var size := control.size if control.size != Vector2.ZERO else control.get_combined_minimum_size()
	control.pivot_offset = size / 2.0
	var tween := control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta(TWEEN_META, tween)
	return tween
