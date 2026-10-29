# Bildschirmfotos aus S3 als eine HTML-Galerie (Bilder eingebettet) bereitstellen
source scripts/m159.sh
mkdir -p shots && aws s3 sync s3://$M159_BUCKET/pub/shots/ shots/ >/dev/null
GAL="${GAL:-}" python3 - <<'P'
import base64, glob, os, re
parts = ['<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#111;color:#eee;font:14px sans-serif} section{height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center} img{height:94vh}</style>']
for i, f in enumerate(sorted(f for f in glob.glob('shots/*.png') if re.search(os.environ.get('GAL',''), f))):
    n = os.path.basename(f)[:-4]
    b = base64.b64encode(open(f, 'rb').read()).decode()
    parts.append(f'<section id="s{i}"><div>{i}: {n}</div><img src="data:image/png;base64,{b}"></section>')
    print(i, n)
open('gallery.html', 'w').write('\n'.join(parts))
P
aws s3 cp gallery.html s3://$M159_BUCKET/pub/gallery.html --content-type text/html >/dev/null && echo GALLERY-OK
