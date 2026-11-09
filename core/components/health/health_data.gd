class_name HealthData
extends Resource
## Stats de supervivencia: vida, regeneración, defensa, esquiva y robo de vida. Genérico (jugador y
## enemigos). Los valores viven en su [code].tres[/code] de [code]data/[/code]; aquí todo vale 0 a
## propósito (ver DECISIONES, «Valores de datos solo en el .tres»). Cada número es una stat
## mejorable. Cómo afecta cada una al combate está en el GDD (§6, «Stats del personaje»).

@export_group("survival")
## Vida máxima.
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_health: float = 0.0
## Vida que se recupera por segundo.
@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:/s") var health_regen: float = 0.0
## Defensa: reduce el daño recibido con rendimientos decrecientes (nunca llega al 100 %).
@export_range(0.0, 500.0, 1.0, "or_greater") var armor: float = 0.0
## Probabilidad de evitar un golpe por completo (como mucho 90 %).
@export_range(0.0, 90.0, 0.5, "suffix:%") var evasion: float = 0.0
## Parte del daño que haces que te cura.
@export_range(0.0, 100.0, 0.5, "or_greater", "suffix:%") var lifesteal: float = 0.0
