# Bro Guild — Documento de diseño

> Documento vivo: si el diseño cambia, se cambia aquí.
>
> **Temática: medieval con humor moderno** (definitiva). Este documento aún conserva nombres de la temática anterior (casino); los que hay que adaptar están en §11. Las tragaperras se quedan.

## 1. Pitch
Roguelike de hordas en 3D donde **moverte bien es dinero**: la velocidad alimenta tu racha, la racha multiplica tu oro y el oro se apuesta. Partidas de ~10 minutos, caos constante, reinicio instantáneo y el clásico "una más".

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
| Segundos | Moverte (dash, slide, saltos); las armas disparan solas; recoges XP y el oro vuela solo hacia ti; rompes calaveras y bolsitas con E |
| Minutos | Subes de nivel (ruleta), abres cofres, juegas a la tragaperras, aceptas o rechazas pactos, cobras tu racha |
| Partida | Exploras el nivel juntando llaves; invocas al jefe en su altar (al minuto 10 se activa solo) → lo vences → **¿Cobrar o Doblar?** |
| Entre partidas | Gastas el bote en desbloqueos y vuelves a entrar |

## 4. Movimiento
Cámara en tercera persona a una distancia moderada que crece muy poco a poco con el nivel del personaje: de un nivel a otro casi no se nota, pero hacia el nivel 100 sí hay diferencia (curva en datos). Correr es gratis; casi todo lo demás gasta **stamina** en cargas que se regeneran. Decidir cuándo gastar la última carga es la habilidad.

| Acción | Input | Stamina | Notas |
|---|---|---|---|
| Correr | WASD | — | Como en Deadlock: arrancas acelerando poco a poco y, tras unos segundos moviéndote sin soltar la dirección, pasas a **sprint**, algo más rápido. Mucho control aéreo; el momentum no se pierde de golpe |
| Salto | Espacio | — | Con coyote time y jump buffer |
| Doble salto | Espacio en el aire | 1 | Se recupera al tocar suelo; con mejoras o personajes, más saltos (triple salto). Con coyote time, Espacio es el salto normal |
| Dash | Shift | 1 | Ráfaga corta en la dirección de movimiento (sin dirección, hacia donde mira la cámara); también en el aire, donde va recto. En el suelo necesitas ir a una velocidad mínima (parado no hay dash). Al terminar conservas parte del impulso. Dashes totales = cargas de stamina; en el aire, como mucho los «dashes en el aire» (1 de partida, mejorable), que se recuperan al tocar suelo |
| Dash-jump | Espacio justo tras el dash | +1 | Ventana corta (con aviso visual: un aro dorado en los pies) → salto largo que conserva la velocidad del dash. Solo tras un dash en el suelo (también en dash → slide); pulsado al final del dash, sale al acabar. Sin stamina, Espacio es un salto normal |
| Slide | Ctrl corriendo (mantener) | — | Gratis; acelera cuesta abajo y frena cuesta arriba (en llano frena poco a poco); hurtbox baja (zona donde recibes daño). Empieza y sigue mientras vayas por encima de una velocidad mínima; termina al soltar Ctrl. Con WASD se curva hacia donde pides sin perder velocidad (como en Deadlock). Dash → slide alarga el dash sin gastar más: Ctrl en mitad de un dash en el suelo lo corta y sigue deslizando con la velocidad del dash (o mantén Ctrl al acabarlo). Si aterrizas con Ctrl mantenido y con velocidad, sigues deslizando sin perder impulso: dash → slide → slide-jump → slide |
| Slide-jump | Espacio en slide | — | Conserva el impulso |
| Caída rápida | Ctrl dos veces en el aire | 1 | El «dash hacia abajo»: picado recto al suelo hasta tocarlo (más rápido que la caída normal); con mejoras, impacto en área. Un solo Ctrl en el aire no hace nada (si aterrizas corriendo enseguida, empiezas a deslizar) |
| Salto en pared | Espacio en el aire junto a una pared | 0 / ½ | Al estilo de Deadlock: te impulsa hacia arriba y hacia donde pides, separándote de la pared (si pides hacia la pared, rebota); si ibas más rápido, conservas tu velocidad. El primero gratis; encadenados sin tocar suelo, media carga |
| Mantle | Saltar contra un borde | — | Sube bordes a media altura (de 0,3 a 2,6 m sobre los pies, en datos) con un pico de velocidad; con Ctrl sale deslizando. Funciona en el suelo y en el aire, hacia donde pides o, sin dirección, hacia la cámara |

**Reglas de entrada:** gana la primera acción que pulsas. Una acción empezada no se puede cancelar con otra hasta que termina; la excepción es el dash, que cancela cualquier acción (también otro dash) si quedan cargas. A su vez, el slide puede cortar un dash en el suelo para seguir deslizando con su impulso. Lo que pulsas durante una acción se guarda si falta muy poco para que termine (~0,1 s); si no, se pierde. Si Espacio puede hacer varias cosas a la vez, gana mantle > salto en pared > dash-jump > doble salto (orden en datos).

**Valores de partida** (viven en `data/player/movement.tres` y se ajustan jugando): 3 cargas; recarga de una carga cada ~3 s; dash de ~0,2 s.

**Arena al servicio del movimiento:** rampas para slides, bordes a media altura para mantle, paredes para saltos, desniveles y plataformas. Correr en llano debe ser la opción lenta.

**Objetivo de feel:** cruzar la arena de punta a punta en menos de 5 s con buena técnica; un jugador nuevo debe poder hacer un dash-jump en su primera partida.

## 5. Apuestas (el corazón del juego)
Toda apuesta tiene **anticipación** (giro, luces, sonido que sube), **revelado** claro por color y **coste creciente**: repetir nunca es gratis.

**Rarezas** (mismo color en todo el juego): Común (gris) · Rara (verde) · Improbable (azul) · De leyenda (amarillo) · Mítica (rojo). Pesos de partida 60/25/10/4/1; la **Suerte** sube el peso de las altas (cada punto, +1 / +2 / +3 / +5 % del suyo a rara, improbable, de leyenda y mítica).

1. **Ruleta de nivel** — al subir de nivel, 3 cartas giran como rodillos y caen en una rareza; eliges una.
   - *Reroll:* cuesta oro y el coste sube con cada uso en la partida.
   - *Doble o nada:* tras elegir, puedes apostar la carta: ~50 % sube una rareza, ~50 % la pierdes. La Suerte mejora las probabilidades.
2. **Cofres** — repartidos por el nivel y soltados por élites. Abrirlos cuesta oro (sube con la dificultad y con cada cofre abierto en la partida). Revelado tipo "case opening": la luz recorre las rarezas antes de pararse. Dan **objetos pasivos** (§6).
3. **Tragaperras** — máquinas repartidas por el nivel (también en sitios a los que hay que subir). Pagas oro (sube con la dificultad y cada vez que usas esa máquina) y giran 3 rodillos sin pausar el juego. Cada máquina aguanta 5 tiradas y luego revienta. Símbolos: moneda (pareja: oro ×2 de lo pagado; trío: ×10), corazón (cura un 30 %; trío: vida al máximo), estrella (sube un nivel un arma o runa al azar; trío: tres) y calavera, la **maldición** (pareja: −20 % de vida máxima un minuto; trío: cinco élites). Sin dos iguales, nada. El trío (jackpot) va con cámara lenta.
4. **Racha y bote** — matar encadenado y moverte rápido sube la racha (×1 → ×2 → ×3 → ×5), que multiplica oro, XP y Suerte. Lo ganado con racha va a un **bote** que hay que **cobrar** (mantener E un segundo quedando vulnerable, o en una tragaperras). Si te golpean con el bote lleno, pierdes la mitad y bajas un nivel. Quedarte quieto la enfría.
5. **Pactos de la Banca** — de vez en cuando, una oferta: aceptas una maldición para el resto de la partida (más enemigos, menos curación…) a cambio de Suerte o multiplicador. Se puede rechazar.
6. **¿Cobrar o Doblar?** — al vencer al jefe: *Cobrar* termina la partida y guarda el bote. *Doblar* abre la siguiente mesa, más dura, con el bote ×2; si mueres ahí, te llevas solo la mitad.

**Stats mejorables:** como en Megabonk, cualquier stat del personaje se puede subir o bajar con mejoras, rasgos de personaje y maldiciones: velocidad de carrera, altura de salto, control aéreo, stamina, daño… Una stat nueva es mejorable desde que existe.

**Mejoras con sinergia de movimiento** (ejemplos): el slide deja un rastro de fuego · cada dash suelta una onda que empuja y daña · más daño mientras estás en el aire · la caída rápida explota al aterrizar · cada carga de stamina sin gastar da crítico extra.

**Mejoras que tocan el azar** (ejemplos): Dado trucado (1 reroll gratis por nivel) · Amigo del crupier (las maldiciones de la tragaperras a veces son premio) · Mano caliente (cofres más baratos con racha alta).

## 6. Combate
- **Armas automáticas** (como en Megabonk o Vampire Survivors): atacan solas al objetivo más cercano o al grupo más denso; tú te centras en moverte. Ranuras: 4 de armas y 4 de runas, hasta nivel 10 las armas y 20 las runas (Multiplicidad, 3); al empezar solo hay 2 de cada abiertas y las otras 2 se desbloquearán (cómo, por decidir; en el HUD se ven cerradas). Todo en datos.
- **Armas iniciales**:
  - **Espada** (cuerpo a cuerpo): la cantidad de proyectiles también le afecta (más tajos).
  - **Bastón de mago**: proyectiles que explotan al contacto, con daño en área.
  - **Daga**: proyectil rápido que da a un solo enemigo. Su **rebote** hace saltar el golpe con todo su daño al enemigo más cercano, hasta una distancia máxima: empieza con 2 y sus mejoras lo suben.
  - Las armas de proyectiles (bastón y daga) también pueden mejorar la **velocidad de su proyectil** al subir de nivel.
- **Runas** (pasivas): suben stats principales con cada nivel: Fuerza (daño) · Amplitud (área) · Prisa (velocidad de ataque) · Vigor (vida máxima) · Multiplicidad (cantidad de proyectiles, también para armas cuerpo a cuerpo). Cada proyectil es un golpe entero más, así que Multiplicidad llega como mucho a nivel 3. Al subir un arma, la mejora de proyectiles sale la mitad de veces que las demás.
- **Objetos de la partida** (aparte de armas y runas):
  - *Pasivos:* como los objetos de Megabonk. Salen de cofres y del jefe, tienen rareza, no ocupan ranura y se apilan: cada copia suma su efecto (+% daño, robo de vida, más oro…). Van de cultura bro en general (el gimnasio es un tema más): batido de proteínas, pizza fría de ayer, riñonera, mando de consola, gorra hacia atrás, chanclas con calcetines, rasca y gana, altavoz portátil, gafas de sol, aceite corporal, cinturón de levantar, mancuerna de oro, batido sospechoso (más daño y más dificultad), cadena de oro y la corona del Bro.
  - *Power-ups del suelo:* imán (atrae toda la experiencia del mapa), comida (cura), bomba (daño a todo lo cercano) y bebida energética (más velocidad, velocidad de ataque y daño durante unos segundos). Salen de una tabla de botín con la **probabilidad de botín** (stat del jugador, muy baja: 0,5 % por enemigo normal), que multiplican los élites (×8) y los rompibles (×12). Más adelante, la misma tirada podrá dar cofres.
  - *Llaves del jefe:* repartidas por el nivel, lejos de donde apareces, con una columna de luz que se ve de lejos; se cogen con «interactuar». Con las suficientes se puede invocar al jefe antes de tiempo (§9). En el Brosque son tarjetas de socio: hay las justas, 3.
- **Rompibles** (como los jarrones de Megabonk): calaveras que sueltan experiencia y bolsitas que sueltan oro, repartidas por el nivel. Se rompen **con «interactuar» (E)**, no con ataques: premian moverse por el mapa y pararse un instante.
- **Subir de nivel**: eliges 1 de 3 opciones (arma o runa nueva, o subir una que ya tengas). Cada mejora tiene **rareza**, que se ve en el color del borde de la carta: común (gris), rara (verde), improbable (azul), de leyenda (amarilla) y mítica (roja). Cada arma tiene varias stats que puede mejorar (la espada: daño, cantidad, área y velocidad de ataque) y la rareza decide cuántas toca y cuánto: una común, una; las raras, varias; la mítica, todas, y más fuertes. La ruleta de apuestas (§5) se monta encima de esta elección.
- **Enemigos**: enjambre cuerpo a cuerpo (rápido, frágil) · tanque lento · tirador a distancia (te obliga a moverte) · jefes (uno por nivel, §9) · élites: cualquier enemigo puede salir élite, con una probabilidad que sube con los minutos (más grande, más vida y daño, suelta más experiencia y oro); más adelante, con afijos y cofre.
- **Cuerpos de los enemigos** (como en Megabonk): chocan con el mundo, con el jugador y entre ellos, y no se hacen daño entre ellos. El jugador no los atraviesa: le bloquean, le dañan al tocarle y puede saltar y quedarse de pie encima. Cuando se atascan, los de atrás trepan sobre los de delante: alrededor del jugador forman un montículo y, si está en alto, se apilan para alcanzarlo.
- **Dificultad y director de oleadas**: la **dificultad** es una stat que sube sola (1 por minuto) y también con objetos o runas: **más riesgo, más recompensa**. De ella dependen cuántos enemigos salen, cuáles, cuántos élites y lo fuertes que son (vida y daño), todo en curvas de datos; los picos de cada minuto van por el reloj. También sube lo que sueltan calaveras y bolsitas. La ronda normal dura 10 min: hacia la dificultad 10 los enemigos se disparan (hace falta buena build para aguantar un poco) y en el minuto 10 el altar del jefe se activa solo.

**Stats del personaje** (como en Megabonk o Vampire Survivors; todas mejorables, §5). Valores de partida en `data/player/`. Ya funcionan vida, regeneración, defensa, esquiva, daño y crítico; el resto de fórmulas son la intención de diseño y se confirman al implementar armas y enemigos (Hito 2). Al recibir un golpe, primero se tira la esquiva y luego la defensa reduce lo que entra.

| Grupo | Stat | De partida | Efecto |
|---|---|---|---|
| Supervivencia | Vida máxima | 100 | |
| | Regeneración de vida | 0 /s | Vida por segundo |
| | Defensa | 0 | Daño recibido × 100 / (100 + defensa): 100 de defensa = mitad de daño, nunca inmune (ese 100 está en `data/combat/rules.tres`) |
| | Esquiva | 0 % (máx. 90 %) | Probabilidad de evitar un golpe entero |
| | Robo de vida | 0 % | Parte del daño hecho que te cura |
| Ataque | Daño | 100 % | Multiplica el daño de todas las armas |
| | Probabilidad de crítico | 5 % (máx. 100 %) | |
| | Daño crítico | 150 % | Un crítico hace este % del golpe |
| | Velocidad de ataque | 100 % | Divide el tiempo entre ataques de cada arma |
| | Proyectiles extra | 0 | Se suman a los de cada arma |
| | Velocidad de proyectil, área, duración, retroceso | 100 % | Multiplican lo de cada arma |
| Progresión | Experiencia ganada, oro ganado | 100 % | |
| | Suerte | 0 | Sube el peso de las rarezas altas (con 100, la mítica pasa del 1 al 3,7 %) |
| | Radio de recogida | 3 m | Distancia a la que se recoge el botín |
| | Dificultad | 0 (+1 por minuto) | Enemigos más numerosos y fuertes, más botín de los rompibles (sube con objetos o runas) |
| | Probabilidad de botín | 0,5 % | Que un enemigo normal suelte un power-up (o, más adelante, un cofre); ×8 los élites y ×12 los rompibles |
| Movimiento | Velocidad de carrera, saltos y dashes en el aire, stamina… | ver §4 | |

Las mejoras de % («+10 % de daño») multiplican; las de puntos («+5 % de crítico», «+1 proyectil», «+1 salto en el aire») suman.

## 7. Estética: sencilla pero llamativa
Dirección: **medieval con humor moderno**, nada realista; los anacronismos son bienvenidos (p. ej., tragaperras repartidas por un mundo medieval). Formas simples (primitivas o low-poly) que luzcan sin necesitar artista. *Pendiente: concretar la dirección visual (sustituye a la anterior «casino-arcade neón»).*
- **Color con significado**: cada tipo de enemigo con su color; las rarezas, iguales en cofres, cartas, números y luces.
- **Juice**: hit-stop en golpes grandes · screen shake por trauma · números de daño (críticos grandes y dorados) · flash al golpear · explosión de monedas al matar · imán de pickups · estela en dash y slide · FOV que se abre con la velocidad y líneas de velocidad · cámara lenta en el jackpot.
- **Sonido**: cada recompensa sube de tono; la racha sube el pitch de todo; los rodillos hacen tic-tic-tic al frenar.
- **UI**: tipografía gruesa, animada con tweens, legible en mitad del caos.
- **Assets**: primitivas + shaders propios; si hace falta, packs CC0 (Kenney, Quaternius).

## 8. Controles
WASD mover · Ratón cámara · Espacio saltar · Shift dash · Ctrl slide (doble Ctrl en el aire: caída rápida) · E interactuar / cobrar · Tab estadísticas · Esc pausa · R reintentar (en los resultados). Todo remapeable.

**Menú de pausa (Esc):** a la izquierda, Continuar, Opciones, Reintentar y Salir; a la derecha, un panel fijo con todas las stats del personaje, resaltando las que han cambiado mejoras o maldiciones. Mando: más adelante.

## 9. Partida y progresión
- **Mesa**: ~10 min (dificultad normal; nivel ~30 al minuto 10 si se mata casi todo). Élites por probabilidad, cada vez más a menudo.
- **Jefe**: cada nivel tiene el suyo en un **altar**. Se invoca con las llaves del nivel cuando te veas fuerte; al minuto 10 el altar se activa solo. Vencerlo antes da más recompensa, y vencerlo pasa el nivel. Mientras tanto siguen las oleadas (desde el minuto 10, la prórroga, muy fuertes). Sale más fuerte cuanto más alta esté la dificultad.
  - *Premio:* oro por un multiplicador que baja con los minutos (×3 al empezar, ×1 desde el minuto 10) y un objeto pasivo de rareza alta (improbable o más), revelado en el HUD. Luego, la pantalla de victoria con las estadísticas y el premio por rapidez. Hasta que exista «¿Cobrar o Doblar?» (Hito 8), la partida termina ahí.
  - *El Ent-renador* (jefe del Brosque): un árbol enorme vestido de entrenador personal (polo, cinta en la frente y silbato), con su barra de vida y sus gritos en el HUD («¡Una más!», «¡Sin excusas!»). Su altar está al borde del claro. Ataques: *Burpee* (se agacha, salta adonde estabas —un aro marca dónde cae— y suelta una onda por el suelo que se esquiva saltándola o alejándote), *Series* (apunta con una franja en el suelo y embiste en línea recta tres veces) y *Bro-tes* (llama a unos arbolitos rápidos y frágiles que te persiguen). Por debajo de la mitad de su vida entra en rabia: más rápido, ataca más a menudo y llama más Bro-tes.
- **Monedas**: XP (niveles) · Oro (en partida, se apuesta; lo suelta cada enemigo y llega solo al matarlo) · Bote (sale de la partida y se gasta fuera).
- **Meta-progresión**: desbloquear personajes (cada uno con un rasgo de movimiento: triple salto, dash más largo, slide más rápido…), armas iniciales y ventajas pequeñas. Nunca más poder bruto que el que da jugar bien.
- **Personajes**: todos parten de las mismas stats básicas y cada uno cambia unas pocas según su gimmick (p. ej., +1 salto en el aire y −10 % de vida). Esas diferencias son su base: en el menú no salen como mejoras. Cada uno tiene un arma principal y una habilidad pasiva. Iniciales:

  | | Guerrero | Mago | Pícaro |
  |---|---|---|---|
  | Arma inicial | Espada | Bastón de mago | Daga |
  | Stats | +30 vida, +5 defensa, −5 % velocidad | −20 vida, +15 % área, +10 % experiencia | −10 vida, +10 % velocidad, +10 % crítico, +1 carga de stamina |
  | Movimiento | Dash un 30 % más largo | Planea manteniendo el salto (cae como mucho a 3 m/s) | +1 salto en el aire, con un mortal hacia delante |
  | Regeneración | 0,8 de vida/s | 0,4 de vida/s | 0,5 de vida/s |
  | Pasiva (crece con cada nivel) | **Veterano**: +1 % de daño por cada nivel | **Expansión arcana**: +1 % de área por cada nivel | **Letal**: +1 % de probabilidad de crítico por cada nivel |

- **Menús**: al iniciar, menú principal con Jugar, Archivo y Abandonar (cierra el juego).
  - *Jugar* → selección de personaje: lista a la izquierda, su modelo 3D en el centro y, al pasar el ratón, un panel a la derecha con nombre, stats, arma principal y habilidad pasiva. Al elegir, ese panel se cambia por la selección de nivel.
  - *Niveles*: el Brosque (en inglés, the Brorest), la Torre del Mago y la Mazmorra. El Brosque es un **gimnasio en el bosque**: bosque low-poly de colores vivos con humor (rocas con forma de pesas, troncos-banco, carteles de «No pain, no gain») y ruinas pequeñas de piedra con musgo (un templo de columnas, muros rotos y arcos) que le dan el toque medieval, tragaperras entre los árboles y mesetas para moverse en vertical. Empieza sencillo y gana detalles con el tiempo.
  - *Archivo*: personajes, armas, runas y enemigos. Cada entrada se desbloquea al conseguirla o al derrotar a ese enemigo; mientras tanto sale como «???».
- **Reinicio**: de la muerte a una partida nueva en menos de 2 s.

## 10. Fuera de alcance por ahora
Multijugador · historia · generación procedural de mapas (de momento, arenas hechas a mano) · consolas.

## 11. Decisiones abiertas
- Adaptar a la temática medieval los nombres y elementos que vienen del casino: bote, La Banca, crupier, mesa, «¿Cobrar o Doblar?» y estética neón (§7). Las tragaperras se quedan. Las fichas ya son oro.
