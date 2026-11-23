# Lore de Bro Guild

Este archivo es tuyo: cámbialo cuando quieras. Es la referencia de la historia y el tono del juego.

**Ojo:** los textos que salen *dentro del juego* no se leen de aquí. Están en `data/i18n/strings.csv`, con su clave (por ejemplo, `LEVEL_BROSQUE_LORE`), en español y en inglés. Si cambias algo aquí que también sale en el juego, cambia esa línea del CSV o pídemelo. En cada sección pongo qué claves le tocan.

## El mundo: el Gremio de los Bros

Un reino medieval con humor moderno. El Gremio de los Bros reúne a los aventureros más mazados del reino: gente que trata cada misión como una sesión de gimnasio y cada monstruo como una serie más. Los anacronismos son bienvenidos: tragaperras entre ruinas, bebidas energéticas en el botín, rascas en los cofres.

El Gremio manda a sus bros a torneos por distintos lugares del reino. Sobrevivir, hacerse fuerte por el camino y tumbar al jefe del sitio es la única forma de subir de rango. El tahúr del Gremio pone las tragaperras; el botín se lo queda quien vuelve entero.

## Los bros (personajes)

- **El Guerrero** (`CHARACTER_WARRIOR_*`): espada, escudo y ni un día sin entrenar. Cuantos más niveles, más pega.
- **El Mago** (`CHARACTER_MAGE_*`): estudió más que entrenó, pero sus orbes no perdonan. Cada nivel, sus hechizos ocupan más.
- **El Pícaro** (`CHARACTER_ROGUE_*`): dos dagas, cero escrúpulos y un ojo para los críticos.

## El Brosque (primer nivel)

Claves en el juego: `LEVEL_BROSQUE_NAME`, `LEVEL_BROSQUE_GOAL`, `LEVEL_BROSQUE_LORE` y los mensajes de bienvenida `BROSQUE_INTRO_*`.

Un bosque viejísimo convertido en gimnasio al aire libre. Entre los robles hay pesas de piedra que nadie es capaz de levantar, bancos de tronco y ruinas cubiertas de musgo. Al norte, pegada a la muralla, la taberna cura a cualquiera que pague (y cada vez cobra más). Por el bosque crecen círculos de setas que ofrecen un objeto a elegir, y el tahúr ha dejado tragaperras por todas partes.

Las tarjetas de socio están repartidas por el bosque. Con tres, se puede llamar al dueño del gimnasio.

**Cómo se gana:** vencer al Ent-renador.

### El Ent-renador (jefe)

Claves: `ENEMY_ENT_TRAINER_*`, `ENT_TRAINER_ARRIVES*`.

Un árbol centenario con polo, cinta en la frente y silbato. Lleva siglos dirigiendo el Brosque y nunca se ha saltado el día de pierna. Entrena a sus **Bro-tes**, arbolitos con su misma cinta, a golpe de silbato. Cuando sale, los llama para que le hagan las series. Sus ataques son ejercicios: *Burpee* (salta y aplasta el suelo) y *Series* (embiste una y otra vez).

### El Trolleador Cara (miniboss)

Claves: `ENEMY_TROLLEADOR_*`, `TROLLEADOR_INCOMING`.

Un troll jorobado que vive bajo el puente del Brosque y cobra peaje a porrazos. Siempre sonríe, y nunca por nada bueno. Aparece a mitad de ronda, entre las dos hordas.

### Los trolls de piedra

Fuera de la muralla este, dos trolls como el Trolleador se quedaron de piedra al amanecer, alrededor de su olla (un guiño a El Hobbit). Dicen que eran sus primos y que discutían la receta. Nadie se atreve a moverlos.

### Los de siempre

- **Esbirros** (`ENEMY_SWARMER_*`): bichos rápidos y frágiles que van en manada.
- **Tiradores** (`ENEMY_SHOOTER_*`): se quedan a distancia y escupen bolas de fuego lentas.
- **Hordas** (`HORDE_INCOMING`): a los minutos 3 y 6 el bosque entero se te echa encima.

## Próximos niveles (por escribir)

- **La Torre del Mago** (`LEVEL_WIZARD_TOWER_*`).
- **La Mazmorra** (`LEVEL_DUNGEON_*`).
