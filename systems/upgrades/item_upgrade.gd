class_name ItemUpgrade
extends StatModifierSet
## Una mejora de un nivel de un arma o runa: sus modificadores y su rareza (vacía: la mejora
## estándar de la armería y las herramientas). Cada una es un objeto propio, para poder quitarla
## sola.

## Rareza con la que salió (o [code]null[/code]).
@export var rarity: Rarity
