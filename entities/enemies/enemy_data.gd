class_name EnemyData
extends Resource
## Un tipo de enemigo: nombre, escena (con su aspecto y sus componentes) y stats (su [HealthData] y
## su [EnemyStats]). Añadir un enemigo es crear su [code].tres[/code] en [code]data/enemies/[/code]
## (y su escena si se ve o se comporta distinto).

## Identificador estable (pool, guardado, desbloqueos del Archivo).
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]ENEMY_SWARMER_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de la descripción.
@export var description_key: StringName = &""
## Icono (Archivo).
@export var icon: Texture2D
## Escena del enemigo: su raíz es un [Enemy].
@export var scene: PackedScene
## Resources de stats del enemigo ([HealthData], [EnemyStats]…): las fuentes de su [StatsComponent].
@export var stat_sources: Array[Resource] = []
## Armas con las que ataca además de al tocar (el tirador, su disparo). Son [WeaponData] como las
## del jugador, pero apuntan a [code]player_hurtbox[/code]; viven en
## [code]data/enemies/weapons/[/code] para que no salgan en la armería ni al subir de nivel.
@export var weapons: Array[WeaponData] = []
