class_name EnemyStats
extends Resource
## Stats de un enemigo además de su vida ([HealthData]): cómo se mueve, cuánto daña al tocar y cómo
## se separa de los demás. Los valores viven en el [code].tres[/code] de cada enemigo
## ([code]data/enemies/[/code]); aquí todo vale 0 a propósito.

@export_group("enemy")
## Velocidad máxima persiguiendo.
@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:m/s") var move_speed: float = 0.0
## Rapidez con la que cambia de velocidad y de dirección.
@export_range(0.1, 500.0, 0.5, "or_greater", "suffix:m/s²") var acceleration: float = 0.0
## Daño de cada golpe al tocar al jugador.
@export_range(0.0, 1000.0, 0.5, "or_greater") var contact_damage: float = 0.0
## Segundos entre golpes mientras sigue tocando.
@export_range(0.05, 10.0, 0.05, "or_greater", "suffix:s") var contact_interval: float = 0.0
## Empuje de cada golpe al tocar (fijo: no lo cambian las mejoras del jugador).
@export_range(0.0, 50.0, 0.5, "or_greater", "suffix:m/s") var knockback: float = 0.0

@export_group("steering")
## Distancia a la que empieza a apartarse de otros enemigos.
@export_range(0.1, 10.0, 0.05, "or_greater", "suffix:m") var separation_radius: float = 0.0
## Fuerza de la separación respecto a su velocidad (0 = se amontonan).
@export_range(0.0, 10.0, 0.05, "or_greater") var separation_weight: float = 0.0
## Velocidad con la que trepa encima de otro enemigo que le tapa el paso (0 = no trepa ni se apila).
@export_range(0.0, 20.0, 0.1, "or_greater", "suffix:m/s") var climb_speed: float = 0.0
## Altura sobre los pies del objetivo hasta la que trepa: alrededor del jugador forman un montículo;
## si el jugador está en alto, se apilan para alcanzarlo.
@export_range(0.0, 20.0, 0.1, "or_greater", "suffix:m") var climb_height: float = 0.0
## Desvío máximo con el que se acerca al objetivo; cada enemigo saca el suyo al aparecer.
@export_range(0.0, 90.0, 1.0, "suffix:°") var approach_spread: float = 0.0
## Distancia a la que se queda del objetivo (un tirador): más lejos se acerca, más cerca se aleja y
## siempre lo mira. 0 = va hasta él.
@export_range(0.0, 50.0, 0.5, "or_greater", "suffix:m") var keep_distance: float = 0.0

@export_group("loot")
## Experiencia que suelta al morir.
@export_range(0.0, 1000.0, 0.5, "or_greater") var xp_reward: float = 0.0
## Oro que suelta al morir (vuela solo hacia el jugador).
@export_range(0.0, 1000.0, 0.5, "or_greater") var gold_reward: float = 0.0
