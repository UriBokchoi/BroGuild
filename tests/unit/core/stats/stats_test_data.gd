extends Resource
## Datos de prueba para los tests de stats: números que deben convertirse en stats y
## propiedades que no.

enum Mode { A, B }

@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:m/s") var speed: float = 9.0
@export_range(0, 5, 1) var jumps: int = 1
@export_range(-10.0, 10.0, 0.1, "or_less") var offset: float = 0.0
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var angle: float = 0.5
@export var free_float: float = 2.0
@export var free_int: int = 3
@export var mode: Mode = Mode.A
@export var enabled: bool = true
@export var curve: Curve
var not_exported: float = 1.0
