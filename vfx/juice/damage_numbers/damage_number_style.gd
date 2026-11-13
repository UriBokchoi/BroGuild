class_name DamageNumberStyle
extends Resource
## Aspecto y animación de los números de daño: salen de encima del enemigo con un salto en arco,
## aparecen con un «pop» de escala y se desvanecen al caer. Los críticos, en su color y más
## grandes. Los valores viven en [code]data/vfx/damage_numbers.tres[/code]; aquí todo vale 0.

@export_group("look")
@export var normal_color: Color = Color(0, 0, 0, 0)
@export var critical_color: Color = Color(0, 0, 0, 0)
@export var outline_color: Color = Color(0, 0, 0, 0)
@export var font: Font
@export_range(1, 256, 1) var font_size: int = 0
@export_range(0, 64, 1) var outline_size: int = 0
## Tamaño en pantalla de cada píxel de la fuente (los números miden lo mismo a cualquier distancia).
@export_range(0.0001, 0.05, 0.0001) var pixel_size: float = 0.0
## Tamaño de los críticos respecto a los normales.
@export_range(1.0, 4.0, 0.05) var critical_scale: float = 0.0

@export_group("motion")
## Segundos que dura cada número.
@export_range(0.1, 5.0, 0.05, "suffix:s") var lifetime: float = 0.0
## Velocidad hacia arriba al salir.
@export_range(0.0, 30.0, 0.1, "suffix:m/s") var launch_speed: float = 0.0
## Velocidad hacia un lado al azar al salir (como mucho).
@export_range(0.0, 30.0, 0.1, "suffix:m/s") var spread_speed: float = 0.0
@export_range(0.0, 100.0, 0.1, "suffix:m/s²") var gravity: float = 0.0
## Desplazamiento al azar del punto de salida, para que los golpes seguidos no se tapen.
@export_range(0.0, 2.0, 0.01, "suffix:m") var spawn_jitter: float = 0.0

@export_group("pop")
## Escala al aparecer, que baja hasta 1 con un pequeño rebote.
@export_range(1.0, 4.0, 0.05) var pop_scale: float = 0.0
@export_range(0.01, 1.0, 0.01, "suffix:s") var pop_time: float = 0.0
## Parte de la vida (0–1) a partir de la que se desvanece.
@export_range(0.0, 1.0, 0.01) var fade_start: float = 0.0
