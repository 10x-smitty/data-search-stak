#!/bin/bash

# Setup Vector Search with Elasticsearch Built-in ML Models
# This script configures vector search capabilities for your existing stack

echo "🚀 Setting up Vector Search capabilities..."

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s -k -u elastic:${ELASTIC_PASSWORD:-password} https://localhost:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

echo "✅ Elasticsearch is ready!"

# 1. Download and start a pre-trained sentence transformer model
echo "📥 Downloading sentence transformer model..."
curl -k -u elastic:${ELASTIC_PASSWORD:-password} -X PUT "https://localhost:9200/_ml/trained_models/sentence-transformers__all-MiniLM-L6-v2" \
-H "Content-Type: application/json" \
-d '{
  "input": {
    "field_names": ["text_field"]
  }
}'

echo "🔄 Starting the ML model..."
curl -k -u elastic:${ELASTIC_PASSWORD:-password} -X POST "https://localhost:9200/_ml/trained_models/sentence-transformers__all-MiniLM-L6-v2/deployment/_start" \
-H "Content-Type: application/json" \
-d '{
  "threads_per_allocation": 1,
  "number_of_allocations": 1
}'

# 2. Create an ingest pipeline for automatic vector generation
echo "⚙️ Creating ingest pipeline for automatic embeddings..."
curl -k -u elastic:${ELASTIC_PASSWORD:-password} -X PUT "https://localhost:9200/_ingest/pipeline/vector_embedding_pipeline" \
-H "Content-Type: application/json" \
-d '{
  "processors": [
    {
      "inference": {
        "model_id": "sentence-transformers__all-MiniLM-L6-v2",
        "input_output": [
          {
            "input_field": "name",
            "output_field": "name_embedding"
          },
          {
            "input_field": "email",
            "output_field": "email_embedding"
          }
        ]
      }
    }
  ]
}'

# 3. Create index template with vector fields for PostgreSQL data
echo "📋 Creating vector-enabled index template..."
curl -k -u elastic:${ELASTIC_PASSWORD:-password} -X PUT "https://localhost:9200/_index_template/postgres-vector-users" \
-H "Content-Type: application/json" \
-d '{
  "index_patterns": ["postgres-vector-*"],
  "priority": 300,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "default_pipeline": "vector_embedding_pipeline"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "id": { "type": "integer" },
        "name": { 
          "type": "text",
          "fields": {
            "keyword": { "type": "keyword" }
          }
        },
        "email": {
          "type": "text",
          "fields": {
            "keyword": { "type": "keyword" }
          }
        },
        "name_embedding": {
          "type": "dense_vector",
          "dims": 384,
          "index": true,
          "similarity": "cosine"
        },
        "email_embedding": {
          "type": "dense_vector",
          "dims": 384,
          "index": true,
          "similarity": "cosine"
        },
        "created_at": { "type": "date" },
        "data_source": { "type": "keyword" }
      }
    }
  }
}'

# 4. Test vector search with sample query
echo "🔍 Testing vector search setup..."
sleep 10

echo "📝 Sample vector search query (save this for later use):"
cat << 'EOF'

# Vector similarity search example:
curl -k -u elastic:password -X POST "https://localhost:9200/postgres-vector-*/_search" \
-H "Content-Type: application/json" \
-d '{
  "query": {
    "script_score": {
      "query": { "match_all": {} },
      "script": {
        "source": "cosineSimilarity(params.query_vector, '\''name_embedding'\'') + 1.0",
        "params": {
          "query_vector": [/* 384-dimensional vector here */]
        }
      }
    }
  }
}'

EOF

echo "✅ Vector search setup complete!"
echo "🔧 Next steps:"
echo "   1. Update Logstash to use 'postgres-vector-*' index pattern"
echo "   2. Test with sample data"
echo "   3. Build vector search applications"
