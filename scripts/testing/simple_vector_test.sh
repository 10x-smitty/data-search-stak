#!/bin/bash

# Simple vector search test
export $(grep -v '^#' .env | xargs)

echo "=== Music Rights Vector Search Test ==="
echo ""

# Test 1: Simple text search for Beatles songs
echo "1. Searching for Beatles songs with writers John Lennon and Paul McCartney..."
curl -s -k -u "elastic:${ELASTIC_PASSWORD}" \
    "https://localhost:9200/reconciliation-*/_search?pretty" \
    -H "Content-Type: application/json" \
    -d '{
        "query": {
            "bool": {
                "should": [
                    {"match": {"writers": "John Lennon"}},
                    {"match": {"writers": "Paul McCartney"}},
                    {"match": {"title": "Beatles"}}
                ]
            }
        },
        "_source": ["title", "writers", "publishers", "genre", "iswc"],
        "size": 3
    }' | jq '.hits.hits[]._source'

echo ""
echo "2. Searching for Taylor Swift songs..."
curl -s -k -u "elastic:${ELASTIC_PASSWORD}" \
    "https://localhost:9200/reconciliation-*/_search?pretty" \
    -H "Content-Type: application/json" \
    -d '{
        "query": {
            "match": {
                "writers": "Taylor Swift"
            }
        },
        "_source": ["title", "writers", "publishers", "genre", "iswc"],
        "size": 2
    }' | jq '.hits.hits[]._source'

echo ""
echo "3. Count of documents with embeddings:"
curl -s -k -u "elastic:${ELASTIC_PASSWORD}" \
    "https://localhost:9200/reconciliation-*/_count?q=needs_embedding:false" | jq '.count'

echo ""
echo "4. Count of total reconciliation documents:"
curl -s -k -u "elastic:${ELASTIC_PASSWORD}" \
    "https://localhost:9200/reconciliation-*/_count" | jq '.count'
