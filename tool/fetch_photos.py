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
    'viche_pescado': ['viche de pescado', 'viche manabí', 'viche ecuador'],
    'cazuela_pescado': ['cazuela de pescado manabí', 'cazuela de mariscos ecuador', 'cazuela manaba'],
    'tonga_pollo': ['tonga manabí', 'tonga gallina hoja plátano', 'tonga ecuador'],
    'corviche': ['corviche', 'corviches'],
    'bollo_pescado': ['bollo de pescado', 'bollo pescado ecuador'],
    'sango_camaron': ['sango de camarón', 'sango ecuador'],
    'muchines_yuca': ['muchines de yuca', 'muchín yuca'],
    'tortillas_yuca': ['tortillas de yuca', 'tortilla de yuca ecuador'],
    'verde_salprieta': ['salprieta', 'plátano verde asado'],
    'caldo_bolas_verde': ['caldo de bolas de verde', 'bolas de verde'],
    'tigrillo': ['tigrillo ecuatoriano', 'tigrillo plátano'],
    'menestra_lenteja': ['menestra de lenteja ecuador', 'lentil stew rice'],
}

OK_LICENSE = re.compile(
    r'^(cc0|pd|public domain|cc by(-sa)? ?[1-4]\.0|cc-by(-sa)?-[1-4]\.0)', re.I)


# Tiempo máximo de búsqueda: al terminar se guarda lo que se haya bajado.
DEADLINE = time.time() + 25 * 60


def fetch(url, attempts=3):
    for attempt in range(attempts):
        if time.time() > DEADLINE:
            return None
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            return urllib.request.urlopen(req, timeout=30).read()
        except Exception as e:  # noqa: BLE001
            print('  retry', attempt, url[:90], e, flush=True)
            time.sleep(5 * (attempt + 1))
    return None


def api(params):
    data = fetch('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params))
    return json.loads(data) if data else {}


def strip(html):
    return re.sub(r'<[^>]+>', '', html or '').strip()


def thumb_url(orig, size):
    orig = orig.split('?', 1)[0]  # quita parámetros de seguimiento (utm_...)
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
            cands.append({'title': p['title'],
                          'original': (ii.get('url') or '').split('?', 1)[0],
                          'page': (ii.get('descriptionurl') or '').split('?', 1)[0], 'license': lic,
                          'artist': strip(em.get('Artist', {}).get('value'))[:120]})
        time.sleep(1)
    if time.time() > DEADLINE:
        break
    kept = []
    for c in cands[:3]:
        path = f'{OUT}/{rid}_{len(kept)}.jpg'
        # 500 px es un tamaño estándar de Wikimedia (los demás se limitan).
        data = fetch(thumb_url(c['original'], 960), attempts=1) or fetch(
            thumb_url(c['original'], 500))
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
    sheet = Image.new('RGB', (3 * 265 + 170, len(chunk) * 215), 'white')
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
