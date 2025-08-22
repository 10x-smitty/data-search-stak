#!/bin/bash

# Vector Search Examples and Utilities
# Works with any configured embedding strategy

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

ELASTIC_URL="https://localhost:9200"
ELASTIC_USER="elastic"
ELASTIC_PASS="${ELASTIC_PASSWORD:-password}"
INDEX_PATTERN="${VECTOR_INDEX_PREFIX:-postgres-vector}-*"

echo "🔍 Vector Search Examples for: $INDEX_PATTERN"
echo "Strategy: ${VECTOR_EMBEDDING_STRATEGY:-builtin}"
echo ""

# Function to run a query
run_query() {
    local query_name="$1"
    local query_body="$2"
    
    echo "📊 Running: $query_name"
    echo "Query: $query_body"
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X POST "${ELASTIC_URL}/${INDEX_PATTERN}/_search" \
    -H "Content-Type: application/json" \
    -d "$query_body" | jq '.hits.hits[]._source | {name, email, embedding_strategy, embedding_model}' 2>/dev/null || \
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X POST "${ELASTIC_URL}/${INDEX_PATTERN}/_search" \
    -H "Content-Type: application/json" \
    -d "$query_body"
    echo ""
    echo "---"
    echo ""
}

# Example 1: Basic text search (works regardless of vector strategy)
run_query "Basic Text Search" '{
  "query": {
    "multi_match": {
      "query": "alice",
      "fields": ["name", "email"]
    }
  },
  "size": 5
}'

# Example 2: Search by embedding strategy
run_query "Filter by Embedding Strategy" '{
  "query": {
    "term": {
      "embedding_strategy": "'${VECTOR_EMBEDDING_STRATEGY:-builtin}'"
    }
  },
  "size": 5
}'

# Example 3: Aggregation by embedding model
echo "📈 Aggregation: Documents by Embedding Model"
curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X POST "${ELASTIC_URL}/${INDEX_PATTERN}/_search" \
-H "Content-Type: application/json" \
-d '{
  "size": 0,
  "aggs": {
    "embedding_models": {
      "terms": {
        "field": "embedding_model"
      }
    }
  }
}' | jq '.aggregations.embedding_models.buckets' 2>/dev/null || echo "Raw response..."

echo ""
echo "---"
echo ""

# Example 4: Vector similarity search (only if vectors exist)
if [ "${VECTOR_EMBEDDING_STRATEGY:-builtin}" != "disabled" ]; then
    echo "🧠 Vector Similarity Search Example:"
    echo ""
    echo "To perform vector similarity search, you need a query vector."
    echo "Here's the structure:"
    echo ""
    cat << 'EOF'
# Vector Similarity Search Template:
curl -k -u elastic:password -X POST "https://localhost:9200/postgres-vector-*/_search" \
-H "Content-Type: application/json" \
-d '{
  "query": {
    "script_score": {
      "query": { "match_all": {} },
      "script": {
        "source": "cosineSimilarity(params.query_vector, '\''content_embedding'\'') + 1.0",
        "params": {
          "query_vector": [/* Your 384 or 1536 dimensional vector here */]
        }
      }
    }
  },
  "size": 5
}'

# Or using kNN search (Elasticsearch 8.0+):
curl -k -u elastic:password -X POST "https://localhost:9200/postgres-vector-*/_search" \
-H "Content-Type: application/json" \
-d '{
  "knn": {
    "field": "content_embedding",
    "query_vector": [/* Your vector here */],
    "k": 5,
    "num_candidates": 100
  }
}'

# Hybrid search (text + vector):
curl -k -u elastic:password -X POST "https://localhost:9200/postgres-vector-*/_search" \
-H "Content-Type: application/json" \
-d '{
  "query": {
    "bool": {
      "should": [
        {
          "match": {
            "name": "search term"
          }
        },
        {
          "script_score": {
            "query": { "match_all": {} },
            "script": {
              "source": "cosineSimilarity(params.query_vector, '\''content_embedding'\'') + 1.0",
              "params": {
                "query_vector": [/* Your vector here */]
              }
            }
          }
        }
      ]
    }
  }
}'
EOF
    
    echo ""
else
    echo "🚫 Vector search is disabled. Only text-based search available."
fi

# Example 5: Check index health and mappings
echo "🏥 Index Health and Mappings:"
curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} "${ELASTIC_URL}/_cat/indices/${INDEX_PATTERN}?v"

echo ""
echo "📋 Field Mappings:"
curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} "${ELASTIC_URL}/${INDEX_PATTERN}/_mapping" | \
    jq '.[] | keys' 2>/dev/null || echo "Use curl directly to see mappings"

echo ""
echo "🎯 Usage Tips:"
echo ""
echo "1. Text Search:"
echo "   - Use match, multi_match, or bool queries"
echo "   - Search across name, email, content_for_embedding fields"
echo ""
echo "2. Vector Search:"
echo "   - Generate query vector using same method as indexed data"
echo "   - Use script_score or kNN for similarity search"
echo "   - Combine with text for hybrid search"
echo ""
echo "3. Filtering:"
echo "   - Filter by embedding_strategy to compare methods"
echo "   - Filter by data_source, table_name, etc."
echo ""
echo "4. Switching Strategies:"
echo "   - Update VECTOR_EMBEDDING_STRATEGY in .env"
echo "   - Run ./setup-configurable-vector-search.sh"
echo "   - Restart logstash-postgres service"
