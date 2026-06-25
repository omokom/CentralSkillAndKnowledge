#!/usr/bin/env python3
"""
Milvus 向量搜索脚本 — 供 multi_search skill 调用
用法: python milvus_search.py <query> [--limit N] [--host HOST] [--port PORT]
"""
import argparse, json, sys, urllib.request
from pymilvus import MilvusClient

EMBED_URL = 'http://127.0.0.1:9000/v1/embeddings'
MILVUS_URI = 'http://127.0.0.1:19530'
COLLECTION = 'gbrain_knowledge'

def get_embedding(text: str) -> list:
    payload = json.dumps({
        'model': 'text-embedding-3-large',
        'input': [{'type': 'text', 'text': text}]
    }).encode()
    req = urllib.request.Request(EMBED_URL, data=payload, headers={'Content-Type': 'application/json'})
    resp = json.loads(urllib.request.urlopen(req, timeout=30).read())
    return resp['data'][0]['embedding']

def main():
    parser = argparse.ArgumentParser(description='Search Milvus vector database')
    parser.add_argument('query', help='Search query text')
    parser.add_argument('--limit', type=int, default=5, help='Max results')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', default='19530')
    args = parser.parse_args()

    uri = f'http://{args.host}:{args.port}'
    client = MilvusClient(uri)

    if not client.has_collection(COLLECTION):
        print(json.dumps({'error': 'Collection not found', 'results': []}))
        sys.exit(0)

    vec = get_embedding(args.query)
    results = client.search(
        collection_name=COLLECTION,
        data=[vec],
        anns_field='embedding',
        search_params={'metric_type': 'COSINE', 'params': {'nprobe': 10}},
        limit=args.limit,
        output_fields=['slug', 'title', 'content', 'source']
    )

    hits = []
    for hit in results[0]:
        hits.append({
            'score': round(hit['distance'], 4),
            'title': hit['entity'].get('title', ''),
            'slug': hit['entity'].get('slug', ''),
            'content': hit['entity'].get('content', '')[:300],
            'source': 'milvus'
        })

    print(json.dumps({'results': hits}, ensure_ascii=False))

if __name__ == '__main__':
    main()
