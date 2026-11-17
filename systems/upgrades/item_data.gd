@abstract
class_name ItemData
extends Resource
## Algo que el jugador lleva y sube de nivel durante una partida: un arma ([WeaponData]) o una runa
## ([RuneData]). Es lo que ofrecen la elección de subir de nivel, el Archivo y la armería de
## práctica.

## Identificador estable (guardado, desbloqueos): no cambia aunque cambie el nombre.
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]WEAPON_SWORD_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de la descripción.
@export var description_key: StringName = &""
## Icono (HUD, cartas de subir de nivel). Los de serie están en
## [code]assets/textures/icons/[/code].
@export var icon: Texture2D


## Nivel máximo.
@abstract func max_level() -> int


## Clave de traducción de qué es (arma, runa…), para mostrarlo.
@abstract func kind_key() -> StringName


## Modificadores que trae el nivel [param level] (vacío si ese nivel no cambia stats, como el 1 de
## un arma).
@abstract func level_modifiers(level: int) -> Array[StatModifier]
