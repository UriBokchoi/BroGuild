class_name MovementSynergyData
extends Resource
## El daño de las mejoras de movimiento (GDD §6): el rastro de fuego del slide, la onda del dash y
## la explosión de la caída rápida. Valen 0 sin su objeto y cada copia los sube.

@export_group("synergy")
## Daño de cada quemadura del rastro de fuego del slide (0 = sin rastro).
@export_range(0.0, 1000.0, 0.5, "or_greater") var fire_trail_damage: float = 0.0
## Daño de la onda que suelta cada dash (0 = sin onda).
@export_range(0.0, 1000.0, 0.5, "or_greater") var dash_wave_damage: float = 0.0
## Daño de la explosión al aterrizar de una caída rápida (0 = sin explosión).
@export_range(0.0, 1000.0, 0.5, "or_greater") var slam_damage: float = 0.0
