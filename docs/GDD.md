# Bro Guild — Documento de diseño

> Documento vivo: si el diseño cambia, se cambia aquí.
>
> **Temática: medieval con humor moderno** (definitiva). Este documento aún conserva nombres de la temática anterior (casino); los que hay que adaptar están en §11. Las tragaperras se quedan.

## 1. Pitch
Roguelike de hordas en 3D donde **moverte bien es dinero**: la velocidad alimenta tu racha, la racha multiplica tus fichas y las fichas se apuestan. Partidas de ~10 minutos, caos constante, reinicio instantáneo y el clásico "una más".

Referencias: **Megabonk** (bucle de hordas, builds rotas, cofres) y **Deadlock** (movilidad con stamina, dash-jump, slide).

## 2. Pilares
Si una idea no sirve al menos a uno, se descarta.
1. **Movimiento con techo alto** — se aprende en un minuto, se domina en semanas.
2. **Todo es una apuesta** — casi cada decisión es riesgo/recompensa, con anticipación y revelado.
3. **Caos legible** — cientos de enemigos y efectos, pero siempre sabes qué te ha golpeado y qué has ganado.
4. **Poder que se nota** — en 10 minutos pasas de esquivar a arrasar.

## 3. Bucle
| Escala | Qué haces |
|---|---|
| Segundos | Moverte (dash, slide, saltos); las armas disparan solas; recoges XP y fichas |
| Minutos | Subes de nivel (ruleta), abres cofres, juegas a la tragaperras, aceptas o rechazas pactos, cobras tu racha |
| Partida | Sobrevives 10 min → jefe **La Banca** → **¿Cobrar o Doblar?** |
| Entre partidas | Gastas el bote en desbloqueos y vuelves a entrar |

## 4. Movimiento
Cámara en tercera persona a una distancia moderada que crece muy poco a poco con el nivel del personaje: de un nivel a otro casi no se nota, pero hacia el nivel 100 sí hay diferencia (curva en datos). Correr es gratis; casi todo lo demás gasta **stamina** en cargas que se regeneran. Decidir cuándo gastar la última carga es la habilidad.

| Acción | Input | Stamina | Notas |
|---|---|---|---|
| Correr | WASD | — | Rápido de base, mucho control aéreo; el momentum no se pierde de golpe |
| Salto | Espacio | — | Con coyote time y jump buffer |
| Doble salto | Espacio en el aire | 1 | |
| Dash | Shift | 1 | Ráfaga corta en la dirección de movimiento; también en el aire |
| Picado | Shift dos veces en el aire, sin dirección | *por decidir* | Dash hacia abajo |
| Dash-jump | Espacio justo tras el dash | +1 | Ventana corta (con aviso visual) → salto largo que conserva la velocidad del dash |
| Slide | Ctrl corriendo | — | Gratis; acelera cuesta abajo y frena cuesta arriba; hurtbox baja (zona donde recibes daño). Dash → slide alarga el dash sin gastar más |
| Slide-jump | Espacio en slide | — | Conserva el impulso |
| Caída rápida | Ctrl en el aire | 1 | Picado al suelo; con mejoras, impacto en área |
| Salto en pared | Espacio contra pared | 0 / ½ | El primero gratis; encadenados sin tocar suelo, media carga |
| Mantle | Saltar contra un borde | — | Sube bordes a media altura con un pico de velocidad; con Ctrl sale deslizando |

**Reglas de entrada:** gana la primera acción que pulsas. Una acción empezada no se puede cancelar con otra hasta que termina; la excepción es el dash, que cancela cualquier acción (también otro dash) si quedan cargas.

**Valores de partida** (viven en `data/player/movement.tres` y se ajustan jugando): 3 cargas; recarga de una carga cada ~3 s; dash de ~0,2 s.

**Arena al servicio del movimiento:** rampas para slides, bordes a media altura para mantle, paredes para saltos, desniveles y plataformas. Correr en llano debe ser la opción lenta.

**Objetivo de feel:** cruzar la arena de punta a punta en menos de 5 s con buena técnica; un jugador nuevo debe poder hacer un dash-jump en su primera partida.

## 5. Apuestas (el corazón del juego)
Toda apuesta tiene **anticipación** (giro, luces, sonido que sube), **revelado** claro por color y **coste creciente**: repetir nunca es gratis.

**Rarezas** (mismo color en todo el juego): Común (gris) · Poco común (verde) · Rara (azul) · Épica (morado) · Legendaria (dorado). Pesos de partida 60/25/10/4/1; la **Suerte** desplaza peso hacia arriba.

1. **Ruleta de nivel** — al subir de nivel, 3 cartas giran como rodillos y caen en una rareza; eliges una.
   - *Reroll:* cuesta fichas y el coste sube con cada uso en la partida.
   - *Doble o nada:* tras elegir, puedes apostar la carta: ~50 % sube una rareza, ~50 % la pierdes. La Suerte mejora las probabilidades.
2. **Cofres** — repartidos por la arena y soltados por élites. Abrirlos cuesta fichas (coste creciente). Revelado tipo "case opening": la luz recorre las rarezas antes de pararse.
3. **Tragaperras** — máquinas en la arena. Pagas y giran 3 rodillos: premio (fichas ×N, mejora, cura), nada o **maldición** (oleada de élites, −vida máxima temporal). Tres iguales = jackpot con cámara lenta.
4. **Racha y bote** — matar encadenado y moverte rápido sube la racha (×1 → ×2 → ×3 → ×5), que multiplica fichas, XP y Suerte. Lo ganado con racha va a un **bote** que hay que **cobrar** (mantener E un segundo quedando vulnerable, o en una tragaperras). Si te golpean con el bote lleno, pierdes la mitad y bajas un nivel. Quedarte quieto la enfría.
5. **Pactos de la Banca** — de vez en cuando, una oferta: aceptas una maldición para el resto de la partida (más enemigos, menos curación…) a cambio de Suerte o multiplicador. Se puede rechazar.
6. **¿Cobrar o Doblar?** — al vencer al jefe: *Cobrar* termina la partida y guarda el bote. *Doblar* abre la siguiente mesa, más dura, con el bote ×2; si mueres ahí, te llevas solo la mitad.

**Mejoras con sinergia de movimiento** (ejemplos): el slide deja un rastro de fuego · cada dash suelta una onda que empuja y daña · más daño mientras estás en el aire · la caída rápida explota al aterrizar · cada carga de stamina sin gastar da crítico extra.

**Mejoras que tocan el azar** (ejemplos): Dado trucado (1 reroll gratis por nivel) · Amigo del crupier (las maldiciones de la tragaperras a veces son premio) · Mano caliente (cofres más baratos con racha alta).

## 6. Combate
- **Armas automáticas**: disparan solas al objetivo más cercano o al grupo más denso; tú te centras en moverte. Ranuras de partida: 4 armas + 4 pasivas (en datos).
- **Armas iniciales (temática casino)**: Fichas arrojadizas (proyectil) · Dados explosivos (área) · Ruleta orbital (orbitan a tu alrededor) · Cartas cortantes (perforan).
- **Enemigos**: enjambre cuerpo a cuerpo (rápido, frágil) · tanque lento · tirador a distancia (te obliga a moverte) · élites con afijos (cada ~2 min, sueltan cofre).
- **Director de oleadas**: la densidad sube con el tiempo, con picos cada minuto; la curva vive en datos.

## 7. Estética: sencilla pero llamativa
Dirección: **medieval con humor moderno**, nada realista; los anacronismos son bienvenidos (p. ej., tragaperras repartidas por un mundo medieval). Formas simples (primitivas o low-poly) que luzcan sin necesitar artista. *Pendiente: concretar la dirección visual (sustituye a la anterior «casino-arcade neón»).*
- **Color con significado**: cada tipo de enemigo con su color; las rarezas, iguales en cofres, cartas, números y luces.
- **Juice**: hit-stop en golpes grandes · screen shake por trauma · números de daño (críticos grandes y dorados) · flash al golpear · explosión de fichas al matar · imán de pickups · estela en dash y slide · FOV que se abre con la velocidad y líneas de velocidad · cámara lenta en el jackpot.
- **Sonido**: cada recompensa sube de tono; la racha sube el pitch de todo; los rodillos hacen tic-tic-tic al frenar.
- **UI**: tipografía gruesa, animada con tweens, legible en mitad del caos.
- **Assets**: primitivas + shaders propios; si hace falta, packs CC0 (Kenney, Quaternius).

## 8. Controles
WASD mover · Ratón cámara · Espacio saltar · Shift dash · Ctrl slide / caída rápida · E interactuar / cobrar · Tab estadísticas · Esc pausa. Todo remapeable. Mando: más adelante.

## 9. Partida y progresión
- **Mesa**: ~10 min. Élite cada ~2 min. Jefe al minuto 10.
- **Monedas**: XP (niveles) · Fichas (en partida, se apuestan) · Bote (sale de la partida y se gasta fuera).
- **Meta-progresión**: desbloquear personajes (cada uno con un rasgo de movimiento: triple salto, dash más largo, slide más rápido…), armas iniciales y ventajas pequeñas. Nunca más poder bruto que el que da jugar bien.
- **Reinicio**: de la muerte a una partida nueva en menos de 2 s.

## 10. Fuera de alcance por ahora
Multijugador · historia · generación procedural de mapas (de momento, arenas hechas a mano) · consolas.

## 11. Decisiones abiertas
- Adaptar a la temática medieval los nombres y elementos que vienen del casino: fichas, bote, La Banca, crupier, mesa, «¿Cobrar o Doblar?», armas iniciales (§6), estética neón y «explosión de fichas» (§7). Las tragaperras se quedan.
- Número de ranuras de armas y pasivas.
