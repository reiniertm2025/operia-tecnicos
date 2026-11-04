# Torrexi — guía para Claude Code

App de Android para los técnicos de la empresa: ver sus órdenes de trabajo, atenderlas y completarlas.
Se hace con **Flutter (Dart)**. El APK se compila en esta PC, sin Android Studio.
(Hubo una primera versión en Expo, casi vacía; quedó respaldada en `D:\Respaldo de C\operia-tecnicos-expo`.)

## Reglas

- Responder siempre en **español**, con palabras sencillas: el dueño no es programador.
- **Cero textos en el código** (regla del dueño, 2 nov 2026): todo lo que ve el técnico va en archivos de texto, nunca escrito en un
  `.dart`. Las frases de pantalla en `lib/l10n/app_es.arb` y `app_en.arb` (mismas claves en los dos) y se usan con
  `Textos.of(context)`; los textos largos (manual, novedades) en archivos de texto propios (`assets/`), no en código.
  Los mensajes de error se devuelven como código o `enum` desde la lógica y la pantalla los traduce. Solo pueden quedar en el código
  los valores que se guardan en la base (`'en_proceso'`, nombres de campos) y separadores como `' · '`.
- Subir a GitHub o entregar un APK **solo cuando el usuario lo pida**.
- **No cambiar datos reales** de la base sin aprobación explícita del usuario.
- Código repetido: correr `bunx jscpd lib --ignore "**/l10n/textos*.dart" --min-tokens 50 --threshold 2` (desde esta carpeta);
  si sale un bloque copiado entre pantallas, pasarlo a un widget o función común (por ejemplo en `pantallas/comun.dart`).
- Pruebas en el teléfono con **Maestro** 2.11.0 (`D:\herramientas\maestro`, necesita `JAVA_HOME=D:\herramientas\jdk21` y el teléfono
  conectado por adb wifi): los flujos van en `.maestro/*.yaml` y se corren con `maestro test .maestro/`. Usar textos que se ven en
  pantalla (en los dos idiomas con `|`). **Nunca `clearState`** (borra la sesión del teléfono) y nada que acepte, empiece o termine
  órdenes reales: eso solo con un técnico y órdenes de prueba que el dueño autorice. Las pruebas usan la sesión del dueño
  («reinier») ya abierta en su teléfono: si la app pide «Entrar», lo toca él (Claude no inicia sesión con su cuenta).
  `.maestro/recorrido-solo-mirar.yaml` recorre el menú, abre una orden y la Ayuda sin cambiar nada. Las capturas pueden mostrar
  lo que haya en la pantalla del teléfono: revisarlas y borrarlas (`build/maestro`, `~/.maestro/tests`).
- Ícono: lo dibuja `diseno/icono.ts` (marca de Torrexi + insignia ✓) y escribe los PNG en `android/app/src/main/res/mipmap-*`.
  Arranque azul marino (`@color/torrexi_marino`, `values-v31/styles.xml`). Para regenerar hace falta `@resvg/resvg-js` (bun add en
  una carpeta aparte y `bun icono.ts <carpeta res> diseno`).
- Emulador `Operia_Pixel` (Android 16, en `D:\herramientas\avd`, variable `ANDROID_AVD_HOME`): arranca, pero ⚠️ **se cierra al abrir
  la app** en esta PC (NVIDIA MX350 con controlador 532.10; el emulador pide ≥ 553.35 para Vulkan, y con gráficos por software o
  sin Vulkan también truena). Hasta actualizar el controlador, probar en el teléfono real.
- Ver el teléfono en la PC: **scrcpy** 5.0.1 en `D:\herramientas\scrcpy` (verificado con su sha256). El dueño lo abre con doble clic
  en `D:\herramientas\espejo-telefono.bat` (sin audio, usa el adb de platform-tools para no chocar con Flutter ni Maestro).
  Funciona (2 nov 2026). La primera vez el teléfono pide permiso en pantalla; la ventana negra del .bat muestra los errores.
  Claude no puede abrir scrcpy (el sistema bloquea ejecutar programas descargados): lo abre el dueño.
- Antes de dar algo por terminado: `flutter analyze` y `flutter test`. Si el cambio lee o escribe en Firebase, revisarlo también con el
  agente `revisor-tecnicos` (`.claude/agents/`), pasándole solo los archivos tocados.
- La web está en un solo archivo enorme (`src/legacy/app.js`): **nunca leerlo entero**, buscar con Grep el campo o la función.
- Git: agregar archivo por archivo, **nunca** `git add -A` ni `git add .` (no se debe colar una llave `*.jks` ni `key.properties`).
- Lo que está a medias o espera decisión del usuario se anota en la memoria `contexto-actual` del proyecto Torrexi.

- Nombre: la web y la app se llaman **Torrexi** (antes Operia, cambio del dueño el 3 nov 2026); en la app no debe verse «Operia».
  Solo se queda el id interno de Android `com.operia.operia_tecnicos` (build.gradle.kts, MainActivity.kt, google-services.json,
  appId de Maestro): está registrado en Firebase y cambiarlo haría otra app distinta (habría que darla de alta en la consola).

## Herramientas (todo en D:, el disco C: está casi lleno)

- Flutter `D:\herramientas\flutter`, Java 21 `D:\herramientas\jdk21`, Android SDK `D:\herramientas\android-sdk`.
- Cachés en D: con las variables de usuario `PUB_CACHE=D:\herramientas\pub-cache` y `GRADLE_USER_HOME=D:\herramientas\gradle`.
- Dos versiones (sabores de Android, `build.gradle.kts`):
  - **Real** (base `cabletech-81e62`, la de los técnicos): `flutter build apk --release` (sabor por defecto, `default-flavor: real`
    en pubspec) → `build\app\outputs\flutter-apk\app-real-release.apk`.
  - **Pruebas** (base aparte `torrexi-pruebas`, no toca datos reales): `flutter build apk --release --flavor pruebas` →
    `app-pruebas-release.apk`. Id `com.operia.operia_tecnicos.pruebas`, se instala junto a la real. Se nota: nombre «Torrexi PRUEBAS»,
    ícono con franja naranja (`src/pruebas/res`, `bun icono.ts <res de pruebas> diseno/pruebas pruebas`), cinta «PRUEBAS» y aviso al
    entrar. Su Firebase: `android/app/src/pruebas/google-services.json` y `lib/firebase_options.dart` (elige según `appFlavor`).
    La web de prueba: `bun run dev:pruebas` en `D:\proyectos\torrexi` (http://localhost:5175); ahí se crean los técnicos de prueba.
  - Lo nuevo se prueba primero en la de prueba. Instalar con `adb install -r` (no desinstalar: se pierde la sesión) en los aparatos
    del dueño: celular `192.168.1.67:5555` y tablet `192.168.1.86:5555` (si cambia de red, `adb mdns services`).
  - Ver cambios al momento: `flutter run --flavor pruebas -d 192.168.1.67:5555` (recarga rápida con `r`, reinicio con `R`).
- Las dos se firman por ahora con la llave de depuración; antes de repartirlas a los técnicos hay que crear una llave propia
  (`*.jks`, nunca se sube a git).

## La base de datos es la misma de la web Torrexi

Firebase `cabletech-81e62`. La web Torrexi (`D:\proyectos\torrexi`, archivo principal `src/legacy/app.js`, reglas `firestore.rules`) es la
referencia de cómo se guardan los datos. **La app debe leer y escribir exactamente igual que la web**, o se rompe lo que ya funciona. Antes
de escribir un campo nuevo, buscar cómo lo usa la web.

### Inicio de sesión de los técnicos (ya existe, hay que respetarlo)

1. El técnico escribe su usuario y contraseña.
2. Se lee `appLogin/{usuario}` → `{ email, salt, iterations, algo: 'PBKDF2-SHA256', userId }` (lectura pública).
3. Se calcula el hash: PBKDF2-SHA256 de la contraseña con `salt` (texto) e `iterations` (100000), 256 bits, en hexadecimal.
4. `signInWithEmailAndPassword(email, hash)` en Firebase Auth (la contraseña de Firebase es ese hash, no la que escribe el técnico).
5. `appAuth/{uid}` → `{ userId }`: con eso las reglas lo reconocen como usuario de la app (`isApp()`), y `userId` es su id en `users`.

Los usuarios de la app (técnicos) están en `users/{userId}` y los crea el administrador desde la web.

### Órdenes de trabajo (`tickets`)

- Estado: `status` = `pendiente` | `en_proceso` | `completada`; cancelada = campo `cancelled: true`.
- Técnico asignado: alguno de `assignedTechId`, `technicianId`, `techId`, `tecnicoId`, `assignedTo`, `acceptedBy`, `acceptedById` (id del usuario).
- Datos del cliente: `clientName`, `clientPhone`, `address`, `latitude`, `longitude`, `zoneId` (localidad), `folio`, `serviceType`,
  `serviceName`, `description`, `workDate` (día de servicio, AAAA-MM-DD), `scheduledTime`, `staffNote` (nota de la oficina), `techComments`.
- Las reglas solo dejan a la app cambiar ciertos campos: revisar `firestore.rules` de la web antes de escribir.

## Cuidado con el plan gratuito de Firebase

50,000 lecturas y 20,000 escrituras al día **para la web y la app juntas**. Escuchar solo las órdenes del técnico (filtradas por su id y
por estado o fecha), nunca colecciones completas.
