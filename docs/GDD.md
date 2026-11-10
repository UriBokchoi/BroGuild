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
| Doble salto | Espacio en el aire | 1 | Se recupera al tocar suelo; con mejoras o personajes, más saltos (triple salto). Con coyote time, Espacio es el salto normal |
| Dash | Shift | 1 | Ráfaga corta en la dirección de movimiento (sin dirección, hacia donde mira la cámara); también en el aire, donde va recto. Al terminar conservas parte del impulso. Dashes totales = cargas de stamina; en el aire, como mucho los «dashes en el aire» (1 de partida, mejorable), que se recuperan al tocar suelo |
| Picado | Shift dos veces en el aire, sin dirección | +1 | Dash hacia abajo: el primer Shift ya hace un dash y el segundo, dentro de una ventana corta, lo convierte en picado |
| Dash-jump | Espacio justo tras el dash | +1 | Ventana corta (con aviso visual: un aro dorado en los pies) → salto largo que conserva la velocidad del dash. Solo tras un dash en el suelo (también en dash → slide); pulsado al final del dash, sale al acabar. Sin stamina, Espacio es un salto normal |
| Slide | Ctrl corriendo (mantener) | — | Gratis; acelera cuesta abajo y frena cuesta arriba (en llano frena poco a poco); hurtbox baja (zona donde recibes daño). Empieza y sigue mientras vayas por encima de una velocidad mínima; termina al soltar Ctrl. Con WASD se curva hacia donde pides sin perder velocidad (como en Deadlock). Dash → slide alarga el dash sin gastar más: Ctrl en mitad de un dash en el suelo lo corta y sigue deslizando con la velocidad del dash (o mantén Ctrl al acabarlo) |
| Slide-jump | Espacio en slide | — | Conserva el impulso |
| Caída rápida | Ctrl en el aire | 1 | Picado recto al suelo hasta tocarlo (más rápido que la caída normal); con mejoras, impacto en área |
| Salto en pared | Espacio en el aire junto a una pared | 0 / ½ | Al estilo de Deadlock: te impulsa hacia arriba y hacia donde pides, separándote de la pared (si pides hacia la pared, rebota); si ibas más rápido, conservas tu velocidad. El primero gratis; encadenados sin tocar suelo, media carga |
| Mantle | Saltar contra un borde | — | Sube bordes a media altura (de 0,3 a 2,6 m sobre los pies, en datos) con un pico de velocidad; con Ctrl sale deslizando. Funciona en el suelo y en el aire, hacia donde pides o, sin dirección, hacia la cámara |

**Reglas de entrada:** gana la primera acción que pulsas. Una acción empezada no se puede cancelar con otra hasta que termina; la excepción es el dash, que cancela cualquier acción (también otro dash) si quedan cargas. A su vez, el slide puede cortar un dash en el suelo para seguir deslizando con su impulso. Lo que pulsas durante una acción se guarda si falta muy poco para que termine (~0,1 s); si no, se pierde. Si Espacio puede hacer varias cosas a la vez, gana mantle > salto en pared > dash-jump > doble salto (orden en datos).

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

**Stats mejorables:** como en Megabonk, cualquier stat del personaje se puede subir o bajar con mejoras, rasgos de personaje y maldiciones: velocidad de carrera, altura de salto, control aéreo, stamina, daño… Una stat nueva es mejorable desde que existe.

**Mejoras con sinergia de movimiento** (ejemplos): el slide deja un rastro de fuego · cada dash suelta una onda que empuja y daña · más daño mientras estás en el aire · la caída rápida explota al aterrizar · cada carga de stamina sin gastar da crítico extra.

**Mejoras que tocan el azar** (ejemplos): Dado trucado (1 reroll gratis por nivel) · Amigo del crupier (las maldiciones de la tragaperras a veces son premio) · Mano caliente (cofres más baratos con racha alta).

## 6. Combate
- **Armas automáticas** (como en Megabonk o Vampire Survivors): atacan solas al objetivo más cercano o al grupo más denso; tú te centras en moverte. Ranuras de partida: 4 armas + 4 runas, cada una hasta nivel 5 (en datos; por defecto, a confirmar jugando).
- **Armas iniciales**:
  - **Espada** (cuerpo a cuerpo): la cantidad de proyectiles también le afecta (más tajos).
  - **Bastón de mago**: proyectiles que explotan al contacto, con daño en área.
  - **Daga**: proyectil rápido que da a un solo enemigo. Sus mejoras pueden subir su **rebote**: el golpe salta con todo su daño al enemigo más cercano, hasta una distancia máxima.
- **Runas** (pasivas): suben stats principales con cada nivel: Fuerza (daño) · Amplitud (área) · Prisa (velocidad de ataque) · Vigor (vida máxima) · Multiplicidad (cantidad de proyectiles, también para armas cuerpo a cuerpo).
- **Subir de nivel**: eliges 1 de 3 opciones (arma o runa nueva, o subir una que ya tengas). La ruleta de apuestas (§5) se monta encima de esta elección.
- **Enemigos**: enjambre cuerpo a cuerpo (rápido, frágil) · tanque lento · tirador a distancia (te obliga a moverte) · élites con afijos (cada ~2 min, sueltan cofre).
- **Director de oleadas**: la densidad sube con el tiempo, con picos cada minuto; la curva vive en datos.

**Stats del personaje** (como en Megabonk o Vampire Survivors; todas mejorables, §5). Valores de partida en `data/player/`. Las fórmulas son la intención de diseño y se confirman al implementar el combate (Hito 2).

| Grupo | Stat | De partida | Efecto |
|---|---|---|---|
| Supervivencia | Vida máxima | 100 | |
| | Regeneración de vida | 0 /s | Vida por segundo |
| | Defensa | 0 | Daño recibido × 100 / (100 + defensa): 100 de defensa = mitad de daño, nunca inmune |
| | Esquiva | 0 % (máx. 90 %) | Probabilidad de evitar un golpe entero |
| | Robo de vida | 0 % | Parte del daño hecho que te cura |
| Ataque | Daño | 100 % | Multiplica el daño de todas las armas |
| | Probabilidad de crítico | 5 % (máx. 100 %) | |
| | Daño crítico | 150 % | Un crítico hace este % del golpe |
| | Velocidad de ataque | 100 % | Divide el tiempo entre ataques de cada arma |
| | Proyectiles extra | 0 | Se suman a los de cada arma |
| | Velocidad de proyectil, área, duración, retroceso | 100 % | Multiplican lo de cada arma |
| Progresión | Experiencia ganada, fichas ganadas | 100 % | |
| | Suerte | 0 | Desplaza los pesos de rareza hacia arriba |
| | Radio de recogida | 3 m | Distancia a la que se recoge el botín |
| Movimiento | Velocidad de carrera, saltos y dashes en el aire, stamina… | ver §4 | |

Las mejoras de % («+10 % de daño») multiplican; las de puntos («+5 % de crítico», «+1 proyectil», «+1 salto en el aire») suman.

## 7. Estética: sencilla pero llamativa
Dirección: **medieval con humor moderno**, nada realista; los anacronismos son bienvenidos (p. ej., tragaperras repartidas por un mundo medieval). Formas simples (primitivas o low-poly) que luzcan sin necesitar artista. *Pendiente: concretar la dirección visual (sustituye a la anterior «casino-arcade neón»).*
- **Color con significado**: cada tipo de enemigo con su color; las rarezas, iguales en cofres, cartas, números y luces.
- **Juice**: hit-stop en golpes grandes · screen shake por trauma · números de daño (críticos grandes y dorados) · flash al golpear · explosión de fichas al matar · imán de pickups · estela en dash y slide · FOV que se abre con la velocidad y líneas de velocidad · cámara lenta en el jackpot.
- **Sonido**: cada recompensa sube de tono; la racha sube el pitch de todo; los rodillos hacen tic-tic-tic al frenar.
- **UI**: tipografía gruesa, animada con tweens, legible en mitad del caos.
- **Assets**: primitivas + shaders propios; si hace falta, packs CC0 (Kenney, Quaternius).

## 8. Controles
WASD mover · Ratón cámara · Espacio saltar · Shift dash · Ctrl slide / caída rápida · E interactuar / cobrar · Tab estadísticas · Esc pausa. Todo remapeable.

**Menú de pausa (Esc):** a la izquierda, Continuar, Opciones, Reintentar y Salir; a la derecha, un panel fijo con todas las stats del personaje, resaltando las que han cambiado mejoras o maldiciones. Mando: más adelante.

## 9. Partida y progresión
- **Mesa**: ~10 min. Élite cada ~2 min. Jefe al minuto 10.
- **Monedas**: XP (niveles) · Fichas (en partida, se apuestan) · Bote (sale de la partida y se gasta fuera).
- **Meta-progresión**: desbloquear personajes (cada uno con un rasgo de movimiento: triple salto, dash más largo, slide más rápido…), armas iniciales y ventajas pequeñas. Nunca más poder bruto que el que da jugar bien.
- **Personajes**: todos parten de las mismas stats básicas y cada uno cambia unas pocas según su gimmick (p. ej., +1 salto en el aire y −10 % de vida). Esas diferencias son su base: en el menú no salen como mejoras. Cada uno tiene un arma principal y una habilidad pasiva. Iniciales: **Guerrero** (espada), **Mago** (bastón de mago) y **Pícaro** (daga); sus diferencias de stats y sus pasivas, por definir.
- **Menús**: al iniciar, menú principal con Jugar, Archivo y Abandonar (cierra el juego).
  - *Jugar* → selección de personaje: lista a la izquierda, su modelo 3D en el centro y, al pasar el ratón, un panel a la derecha con nombre, stats, arma principal y habilidad pasiva. Al elegir, ese panel se cambia por la selección de nivel.
  - *Niveles*: el Brosque (bosque bro), la Torre del Mago y la Mazmorra. Hasta que existan sus mapas, se juega en la zona de pruebas.
  - *Archivo*: personajes, armas, runas y enemigos. Cada entrada se desbloquea al conseguirla o al derrotar a ese enemigo; mientras tanto sale como «???».
- **Reinicio**: de la muerte a una partida nueva en menos de 2 s.

## 10. Fuera de alcance por ahora
Multijugador · historia · generación procedural de mapas (de momento, arenas hechas a mano) · consolas.

## 11. Decisiones abiertas
- Adaptar a la temática medieval los nombres y elementos que vienen del casino: fichas, bote, La Banca, crupier, mesa, «¿Cobrar o Doblar?», estética neón y «explosión de fichas» (§7). Las tragaperras se quedan.
- Diferencias de stats y habilidad pasiva de Guerrero, Mago y Pícaro.
