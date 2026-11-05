# Cómo publicar AppCocina en Google Play

Guía paso a paso. Tómate tu tiempo con el paso 2: la llave de firma es lo
único que **no se puede recuperar** si la pierdes.

## 1. Revisa el identificador de la app

En `android/app/build.gradle.kts` está:

```kotlin
applicationId = "com.jorgemendoza.appcocina"
```

Ese es el ID único de la app en Play Store. **No se puede cambiar después de
publicar.** Si quieres otro, cámbialo ahora (también el `namespace` en ese mismo
archivo y la carpeta `android/app/src/main/kotlin/com/jorgemendoza/appcocina`).

## 2. Crea tu llave de firma (una sola vez)

Necesitas Java (viene con Android Studio). En la terminal:

```bash
keytool -genkey -v -keystore ~/appcocina-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Te pedirá una contraseña y algunos datos. Luego crea el archivo
`android/key.properties` (ya está en `.gitignore`, **nunca lo subas a GitHub**):

```properties
storePassword=LA_CONTRASEÑA_QUE_PUSISTE
keyPassword=LA_CONTRASEÑA_QUE_PUSISTE
keyAlias=upload
storeFile=/ruta/completa/a/appcocina-upload.jks
```

> Guarda una copia del archivo `.jks` y de la contraseña en un lugar seguro
> (por ejemplo, un USB y un gestor de contraseñas). Con la "firma de apps de
> Google Play" (activada por defecto) Google guarda la llave final, y si pierdes
> esta llave de subida puedes pedir que la restablezcan, pero el trámite tarda.

## 3. Sube la versión y compila

En `pubspec.yaml`, la línea `version: 1.0.0+1` significa *nombre 1.0.0,
código 1*. Cada vez que subas una actualización a Play Store, **aumenta el
número después del `+`** (por ejemplo `1.0.1+2`).

```bash
flutter build appbundle --release
```

El archivo para subir queda en:
`build/app/outputs/bundle/release/app-release.aab`

Para probarlo antes en tu celular:

```bash
flutter build apk --release
```

```bash
flutter install --release
```

## 4. Crea la cuenta de desarrollador

1. Entra a https://play.google.com/console y paga el registro único (25 USD).
2. Las **cuentas personales nuevas** deben hacer una **prueba cerrada con al
   menos 12 personas durante 14 días** antes de poder publicar en producción.
   Consigue ese grupo de amigos y familiares desde ya.

## 5. Crea la app en Play Console

**Crear app** → nombre "AppCocina", idioma Español, App, Gratis.

Completa la sección **"Configurar tu app"**:

| Sección | Qué responder |
|---|---|
| Política de privacidad | Una URL pública con el texto de `docs/POLITICA_DE_PRIVACIDAD.md` (ver abajo). |
| Acceso a la app | Toda la funcionalidad está disponible sin restricciones. |
| Anuncios | No contiene anuncios. |
| Clasificación de contenido | Cuestionario: categoría "Referencia, noticias o educación", responde **No** a todo. |
| Público objetivo | 18 años o más (evita los requisitos extra de apps para niños). |
| Seguridad de los datos | La app **no recopila ni comparte datos**. Todo se guarda en el dispositivo. |
| Apps de salud | Marca "Nutrición y dieta / información de salud general". No es una app médica. |
| Gobierno / financiera / noticias | No. |

### URL de la política de privacidad

Play Store necesita un enlace público. Opciones gratis:
- Si el repositorio es público: activa **GitHub Pages** (Settings → Pages) o usa
  el enlace directo al archivo en GitHub.
- Si es privado: pega el texto en un sitio gratuito (Google Sites, Notion
  público, etc.).

## 6. Ficha de la tienda

- **Descripción corta** (máx. 80 caracteres), por ejemplo:
  *Recetas, menús semanales y lista de compras. ¿Qué cocino hoy? ¡Aquí está!*
- **Descripción completa**: puedes partir de la tabla de funciones del README.
- **Ícono** 512×512: usa `assets/icon/icon.png` redimensionado.
- **Gráfico de funciones** 1024×500: una imagen con el nombre y el ícono.
- **Capturas de pantalla**: mínimo 2 de teléfono. Tómalas en tu celular con la
  app instalada (Recetas, Detalle, Modo cocina, ¿Qué cocino?, Mi plan).

## 7. Sube el AAB

1. **Pruebas → Prueba cerrada** → crea una versión → sube `app-release.aab`.
2. Agrega a tus 12+ testers por correo y comparte el enlace de prueba.
3. Tras 14 días, solicita acceso a **Producción** y publica.

La primera revisión de Google puede tardar desde unas horas hasta varios días.

## Lista rápida antes de publicar

- [ ] `applicationId` definitivo
- [ ] `android/key.properties` creado y llave respaldada
- [ ] `version` aumentada en `pubspec.yaml`
- [ ] `flutter test` sin errores
- [ ] Probado en un celular real con `flutter install --release`
- [ ] URL de la política de privacidad lista
- [ ] Capturas e ícono para la ficha
