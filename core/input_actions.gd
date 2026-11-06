class_name InputActions
## Nombres de las acciones del InputMap. El código usa estas constantes, nunca
## cadenas sueltas. Las teclas se asignan en Project Settings > Input Map (teclas
## físicas, para que no dependan de la distribución del teclado), no aquí.
## Una tecla con varios usos es UNA acción; cada estado decide qué significa.

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
## Salto; también doble salto, salto en pared, dash-jump, slide-jump y mantle.
const JUMP: StringName = &"jump"
const DASH: StringName = &"dash"
## Slide en el suelo; caída rápida en el aire.
const SLIDE: StringName = &"slide"
## Interactuar al pulsar; cobrar el bote al mantener.
const INTERACT: StringName = &"interact"
const SHOW_STATS: StringName = &"show_stats"
const PAUSE: StringName = &"pause"

## Todas las acciones propias del juego (sin las ui_* de Godot).
const ALL: Array[StringName] = [
	MOVE_FORWARD,
	MOVE_BACK,
	MOVE_LEFT,
	MOVE_RIGHT,
	JUMP,
	DASH,
	SLIDE,
	INTERACT,
	SHOW_STATS,
	PAUSE,
]
