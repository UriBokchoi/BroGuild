class_name ModelAttachment
extends Resource
## Pieza que un personaje lleva encima (espada, escudo, sombrero…): qué escena y en qué punto del
## modelo ([CharacterModel]) va. Las piezas son assets reutilizables
## ([code]assets/models/props/[/code]); aquí solo se dice dónde y cómo se colocan.

## Escena de la pieza.
@export var scene: PackedScene
## Punto del modelo donde va: el nombre de un hijo de [member CharacterModel.sockets]
## ([code]HandRight[/code], [code]HandLeft[/code], [code]Head[/code]…).
@export var socket: StringName = &""
## Colocación respecto al punto (girar la espada hacia delante, el escudo hacia fuera…).
@export var transform: Transform3D = Transform3D.IDENTITY
