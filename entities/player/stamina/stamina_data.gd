class_name StaminaData
extends Resource
## Parámetros de la stamina del jugador. Los valores viven en [code]data/player/stamina.tres[/code];
## aquí todo vale 0 a propósito (ver DECISIONES, «Valores de datos solo en el .tres»). Cada número
## es una stat, mejorable como las demás. Lo que cuesta cada acción va con su acción.

@export_group("stamina")
## Cargas máximas.
@export_range(0, 10, 1, "or_greater") var max_charges: int = 0
## Segundos que tarda en recargarse una carga.
@export_range(0.1, 10.0, 0.1, "or_greater", "suffix:s") var recharge_time: float = 0.0
