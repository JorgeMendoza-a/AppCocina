# AppCocina 👩‍🍳

App para Android (y iPhone) que ayuda en la cocina del día a día: recetas,
ideas con lo que tienes en casa, menús semanales según tu objetivo y lista de
compras automática. Hecha con **Flutter**, funciona **sin internet** y no
recopila datos personales.

## Funciones (versión 1.0)

| Pantalla | Qué hace |
|---|---|
| **Recetas** | 35 recetas (muchas ecuatorianas y latinas). Búsqueda sin importar tildes, filtros por comida, rápidas, vegetarianas, sin gluten, económicas, altas en proteína y ligeras. |
| **Detalle de receta** | Ajuste de porciones (las cantidades se recalculan), sustitutos de ingredientes, información nutricional aproximada y botón para mandar los ingredientes a la lista de compras. |
| **Modo cocina** | Un paso a la vez con letra grande, temporizadores integrados y pantalla siempre encendida. |
| **¿Qué cocino?** | Marcas los ingredientes que tienes y te dice qué puedes preparar ya y qué te falta, que puedes mandar a la lista con un toque. |
| **Mi plan** | Menú semanal (desayuno, almuerzo, cena y snack) para 6 objetivos: comer saludable, bajar de peso, ganar músculo, vegetariano, sin gluten y económico. Calcula las porciones por persona y arma la lista de compras de la semana. |
| **Compras** | Lista agrupada por categoría, con casillas para marcar, deslizar para borrar y productos propios. |
| **Favoritos** | Tus recetas guardadas. |

Todo lo que guarda el usuario (favoritos, despensa, lista y plan) se queda en el
teléfono.

## Cómo correr la app

1. Instala Flutter (versión estable 3.47 o más nueva):
   https://docs.flutter.dev/get-started/install
2. Instala Android Studio (trae el Android SDK y el emulador).
3. En la carpeta del proyecto:

```bash
flutter pub get
```

```bash
flutter run
```

Con el celular conectado por USB y la "depuración USB" activada, la app se
instala directo en tu teléfono.

### Pruebas

```bash
flutter analyze
```

```bash
flutter test
```

Cada vez que subes cambios a GitHub, el flujo de **GitHub Actions**
(`.github/workflows/ci.yml`) corre el análisis y las pruebas, y compila un APK
y un AAB que puedes descargar desde la pestaña *Actions*.

## Estructura del código

```
lib/
  main.dart                 Arranque: carga recetas y datos del usuario
  app.dart                  Tema (claro/oscuro), idioma español
  models/                   Receta, ingrediente, objetivos de dieta
  data/recipe_repository.dart   Lee assets/data/recipes.json
  services/
    recipe_matcher.dart     "¿Qué cocino?": qué recetas puedes hacer
    plan_generator.dart     Arma el menú semanal y las porciones
    shopping_list_builder.dart  Suma ingredientes para la lista de compras
  state/user_data.dart      Favoritos, despensa, lista, plan (guardado local)
  screens/                  Una pantalla por archivo
  widgets/                  Componentes reutilizables
assets/
  data/recipes.json         Todas las recetas e ingredientes
  icon/                     Ícono de la app
test/                       Pruebas automáticas
```

## Cómo agregar recetas

Edita `assets/data/recipes.json`. Cada receta tiene esta forma:

```json
{
  "id": "mi_receta",
  "name": "Mi receta",
  "emoji": "🍲",
  "description": "Descripción corta",
  "meals": ["almuerzo", "cena"],
  "origin": "Ecuador",
  "minutes": 30,
  "difficulty": "Fácil",
  "servings": 4,
  "tags": ["vegetariano", "sin_gluten", "economico"],
  "nutrition": { "kcal": 400, "protein": 20, "carbs": 50, "fat": 12 },
  "ingredients": [
    { "id": "papa", "qty": 1, "unit": "kg", "note": "en cubos" },
    { "id": "sal", "qty": null, "unit": null }
  ],
  "steps": [
    { "text": "Cocina las papas.", "timerMinutes": 20 },
    { "text": "Sirve caliente." }
  ],
  "tip": "Consejo opcional"
}
```

- `meals`: `desayuno`, `almuerzo`, `cena` o `snack`.
- `ingredients[].id` debe existir en la lista `ingredients` del mismo archivo
  (ahí también se definen los sustitutos).
- `qty: null` significa "al gusto".
- Los valores de `nutrition` son **por porción**.

Después de editar, corre `flutter test`: las pruebas revisan que los ids
existan, que las recetas "sin gluten" no lleven trigo/avena/soya y que las
vegetarianas no lleven carne.

## Publicar en Play Store

Sigue la guía paso a paso: [docs/PUBLICAR_EN_PLAY_STORE.md](docs/PUBLICAR_EN_PLAY_STORE.md).

## Próximas versiones (ideas)

- Asistente con IA para pedidos libres ("algo rápido, sin horno, para 4").
  Necesita un servidor propio para no exponer la clave de la API.
- "Mi recetario": que cada persona guarde sus propias recetas.
- Fotos de las recetas.
- Aviso del temporizador aunque la app esté en segundo plano (notificaciones).
- Compartir la lista de compras por WhatsApp.
