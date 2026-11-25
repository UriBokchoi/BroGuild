class_name UiMotionData
extends Resource
## Cómo se mueve la interfaz ([UiMotion]): saltos, apariciones, botones y barras. Los valores viven
## en [code]data/ui/motion.tres[/code]; aquí todo es neutro a propósito.

@export_group("pop")
## Tamaño en el pico de un salto (un contador que sube, una casilla que cambia) y lo que tarda en
## volver.
@export_range(1.0, 2.0, 0.01) var pop_scale: float = 1.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var pop_time: float = 0.01

@export_group("appear")
## Un panel que aparece: desde este tamaño y transparente, hasta el normal en este tiempo.
@export_range(0.5, 1.0, 0.01) var appear_scale: float = 1.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var appear_time: float = 0.01

@export_group("buttons")
## Tamaño de un botón con el ratón encima (o con el foco) y pulsado, y lo que tarda en llegar.
@export_range(1.0, 1.5, 0.01) var hover_scale: float = 1.0
@export_range(0.5, 1.0, 0.01) var press_scale: float = 1.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var hover_time: float = 0.01

@export_group("bars")
## Lo que tarda una barra en llegar a su valor nuevo.
@export_range(0.01, 2.0, 0.01, "suffix:s") var bar_time: float = 0.01
## El rastro de la vida perdida: lo que espera antes de vaciarse y lo que tarda en hacerlo.
@export_range(0.0, 2.0, 0.01, "suffix:s") var trail_delay: float = 0.0
@export_range(0.01, 2.0, 0.01, "suffix:s") var trail_time: float = 0.01
