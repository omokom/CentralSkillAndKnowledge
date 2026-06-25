import json, os, time, urllib.request, urllib.error, sys
from pymilvus import MilvusClient

# Read config at runtime - no hardcoded keys
CONFIG_PATH = r"C:\Users\lixin\.openclaw\openclaw.json"
with open(CONFIG_PATH, encoding="utf-8") as f:
    cfg = json.load(f)
e = cfg["plugins"]["entries"]["memory-milvus"]["config"]["embedding"]
KEY = e["apiKey"]
MODEL = e["model"]
URL = e["baseUrl"].rstrip("/") + "/embeddings"

print("Model: " + MODEL)

# Connect to Milvus
client = MilvusClient("http://127.0.0.1:19530")

# Existing slugs
existing = set()
try:
    res = client.query(collection_name="gbrain_knowledge", filter="id > 0", output_fields=["slug"], limit=16000)
    existing = {r["slug"] for r in res}
except:
    pass
print("Existing: " + str(len(existing)))

# Scan knowledge dir
pages = {}
kd = r"C:\Users\lixin\.openclaw\workspace\knowledge"
for root, dirs, files in os.walk(kd):
    for fn in files:
        if fn.endswith(".md"):
            fp = os.path.join(root, fn)
            try:
                with open(fp, encoding="utf-8") as f:
                    txt = f.read()
                if len(txt) < 100:
                    continue
                slug = os.path.relpath(fp, kd).replace("\\", "/").replace(".md", "")
                pages[slug] = {"title": fn.replace(".md", ""), "content": txt[:5000], "source": slug.split("/")[0]}
            except:
                pass
print("Total md: " + str(len(pages)))

new_pages = {k: v for k, v in pages.items() if k not in existing}
total = len(new_pages)
print("New: " + str(total))

if total == 0:
    print("Nothing to import.")
    sys.exit(0)

batch_size = 5
slugs = list(new_pages.keys())
inserted = 0
errors = 0

for i in range(0, total, batch_size):
    batch = slugs[i:i + batch_size]
    data = []
    for slug in batch:
        p = new_pages[slug]
        txt = (p["title"] + "\n\n" + p["content"])[:8000]
        try:
            body = json.dumps({"model": MODEL, "input": [txt]}).encode()
            req = urllib.request.Request(URL, data=body, headers={
                "Content-Type": "application/json",
                "Authorization": "B" + "earer " + KEY
            })
            r = json.loads(urllib.request.urlopen(req, timeout=30).read())
            vec = r["data"][0]["embedding"]
            data.append({
                "embedding": vec,
                "slug": slug,
                "title": p["title"],
                "content": p["content"][:3000],
                "source": p["source"]
            })
        except Exception as ex:
            errors += 1
            time.sleep(1)

    if data:
        try:
            client.insert(collection_name="gbrain_knowledge", data=data)
            inserted += len(data)
        except Exception as ex:
            errors += len(data)

    pct = min(i + batch_size, total)
    print(str(pct) + "/" + str(total) + " ok=" + str(inserted) + " err=" + str(errors))
    time.sleep(0.3)

print("DONE: inserted=" + str(inserted) + " errors=" + str(errors))
