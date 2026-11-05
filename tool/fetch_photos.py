"""Busca fotos de platos con licencia libre en Wikimedia Commons.

Lo ejecuta GitHub Actions (.github/workflows/fetch-photos.yml): descarga hasta
4 candidatas por receta en photo_candidates/ junto con meta.json (autor,
licencia, enlace) y hojas de contacto para elegir las mejores.
Solo acepta dominio público, CC0, CC BY y CC BY-SA (permiten uso comercial).
"""
import json, os, re, time, urllib.parse, urllib.request

from PIL import Image, ImageDraw

UA = 'AppCocinaBuilder/1.0 (https://github.com/JorgeMendoza-a/AppCocina)'
OUT = 'photo_candidates'
os.makedirs(OUT, exist_ok=True)

QUERIES = {
    'bolon_verde': ['bolón de verde', 'bolon verde ecuador'],
    'tigrillo': ['tigrillo zaruma', 'tigrillo ecuador comida'],
    'avena_frutas': ['oatmeal banana strawberries bowl', 'porridge fruit'],
    'huevos_pericos': ['huevos pericos', 'scrambled eggs tomato onion'],
    'tostadas_aguacate': ['avocado toast egg'],
    'batido_guineo': ['banana smoothie'],
    'pancakes_avena': ['banana oat pancakes', 'pancakes banana'],
    'encebollado': ['encebollado'],
    'seco_pollo': ['seco de pollo'],
    'menestra_lenteja': ['menestra lenteja', 'lentejas con arroz'],
    'arroz_con_pollo': ['arroz con pollo'],
    'ceviche_camaron': ['ceviche de camarón ecuador', 'ceviche camaron'],
    'locro_papa': ['locro de papa'],
    'pescado_horno': ['baked fish vegetables'],
    'ensalada_quinoa': ['quinoa salad'],
    'pollo_plancha': ['grilled chicken breast salad'],
    'tallarin_saltado': ['tallarín saltado', 'chicken stir fry noodles'],
    'encocado_pescado': ['encocado de pescado', 'encocado'],
    'chaulafan': ['chaulafán', 'chaulafan'],
    'lomo_saltado': ['lomo saltado'],
    'crema_zapallo': ['pumpkin soup', 'crema de zapallo'],
    'sopa_quinoa': ['sopa de quinoa', 'quinoa soup'],
    'caldo_pollo': ['caldo de pollo', 'chicken soup vegetables corn'],
    'tortilla_papa': ['tortilla de patatas', 'spanish omelette'],
    'tacos_frejol': ['bean tacos', 'tacos frijoles'],
    'ensalada_atun': ['tuna salad egg lettuce'],
    'omelette_espinaca': ['spinach omelette'],
    'sanduche_pollo': ['chicken sandwich lettuce tomato'],
    'crema_brocoli': ['broccoli soup', 'cream of broccoli soup'],
    'yogur_granola': ['yogurt granola strawberries'],
    'hummus': ['hummus carrot sticks', 'hummus'],
    'manzana_mani': ['apple slices peanut butter'],
    'huevos_duros': ['boiled eggs halved'],
    'maduro_queso': ['maduro con queso', 'plátano maduro asado queso'],
    'ensalada_frutas': ['fruit salad bowl'],
}

OK_LICENSE = re.compile(
    r'^(cc0|pd|public domain|cc by(-sa)? ?[1-4]\.0|cc-by(-sa)?-[1-4]\.0)', re.I)


def fetch(url):
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            return urllib.request.urlopen(req, timeout=60).read()
        except Exception as e:  # noqa: BLE001
            print('  retry', attempt, url[:90], e)
            time.sleep(10 * (attempt + 1))
    return None


def api(params):
    data = fetch('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params))
    return json.loads(data) if data else {}


def strip(html):
    return re.sub(r'<[^>]+>', '', html or '').strip()


def thumb_url(orig, size):
    name = orig.rsplit('/', 1)[-1]
    url = orig.replace('/wikipedia/commons/', '/wikipedia/commons/thumb/') + f'/{size}px-{name}'
    if name.lower().endswith(('.tif', '.tiff', '.webp')):
        url += '.jpg'
    return url


meta = {}
for rid, queries in QUERIES.items():
    cands, seen = [], set()
    for q in queries:
        res = api({'action': 'query', 'generator': 'search',
                   'gsrsearch': f'{q} filetype:bitmap', 'gsrnamespace': 6,
                   'gsrlimit': 12, 'prop': 'imageinfo',
                   'iiprop': 'url|extmetadata|size', 'format': 'json'})
        pages = sorted(res.get('query', {}).get('pages', {}).values(),
                       key=lambda p: p.get('index', 99))
        for p in pages:
            ii = (p.get('imageinfo') or [{}])[0]
            em = ii.get('extmetadata', {})
            lic = strip(em.get('LicenseShortName', {}).get('value'))
            if p['title'] in seen or not OK_LICENSE.match(lic) or ii.get('width', 0) < 600:
                continue
            seen.add(p['title'])
            cands.append({'title': p['title'], 'original': ii.get('url'),
                          'page': ii.get('descriptionurl'), 'license': lic,
                          'artist': strip(em.get('Artist', {}).get('value'))[:120]})
        time.sleep(1)
    kept = []
    for c in cands[:4]:
        path = f'{OUT}/{rid}_{len(kept)}.jpg'
        data = fetch(thumb_url(c['original'], 960)) or fetch(thumb_url(c['original'], 500))
        if data:
            open(path, 'wb').write(data)
            c['file'] = path
            kept.append(c)
        time.sleep(1)
    meta[rid] = kept
    print(rid, len(kept), flush=True)

json.dump(meta, open(f'{OUT}/meta.json', 'w'), ensure_ascii=False, indent=1)

rows = list(meta.items())
for n in range(0, len(rows), 6):
    chunk = rows[n:n + 6]
    sheet = Image.new('RGB', (4 * 265 + 170, len(chunk) * 215), 'white')
    d = ImageDraw.Draw(sheet)
    for r, (rid, cands) in enumerate(chunk):
        d.text((5, r * 215 + 90), rid, fill='black')
        for i, c in enumerate(cands):
            try:
                t = Image.open(c['file']).convert('RGB')
                t.thumbnail((260, 195))
                sheet.paste(t, (170 + i * 265, r * 215 + 5))
                d.text((170 + i * 265, r * 215 + 200), str(i), fill='red')
            except Exception:  # noqa: BLE001
                pass
    sheet.save(f'{OUT}/sheet_{n // 6}.jpg', quality=80)
