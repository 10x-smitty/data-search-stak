#!/bin/bash

# Configuration-Driven Vector Search Setup
# Reads .env file and configures vector search based on VECTOR_EMBEDDING_STRATEGY

set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
ELASTIC_URL="https://localhost:9200"
ELASTIC_USER="elastic"
ELASTIC_PASS="${ELASTIC_PASSWORD:-password}"
STRATEGY="${VECTOR_EMBEDDING_STRATEGY:-builtin}"

echo "🚀 Setting up Vector Search with strategy: $STRATEGY"

# Wait for Elasticsearch
echo "⏳ Waiting for Elasticsearch to be ready..."
until curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} ${ELASTIC_URL}/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done
echo "✅ Elasticsearch is ready!"

# Function to setup built-in ML model
setup_builtin_ml() {
    local model_name="${VECTOR_BUILTIN_MODEL:-sentence-transformers__all-MiniLM-L6-v2}"
    local dims="${VECTOR_BUILTIN_DIMS:-384}"
    
    echo "📦 Setting up built-in ML model: $model_name"
    
    # Check if model exists
    if ! curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} "${ELASTIC_URL}/_ml/trained_models/${model_name}" | grep -q "model_id"; then
        echo "📥 Downloading model..."
        curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_ml/trained_models/${model_name}" \
        -H "Content-Type: application/json" \
        -d "{\"input\": {\"field_names\": [\"text_field\"]}}" > /dev/null
    fi
    
    # Start model
    echo "🔄 Starting model deployment..."
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X POST "${ELASTIC_URL}/_ml/trained_models/${model_name}/deployment/_start" \
    -H "Content-Type: application/json" \
    -d '{"threads_per_allocation": 1, "number_of_allocations": 1}' > /dev/null 2>&1 || true
    
    # Create pipeline
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_ingest/pipeline/vector_embeddings" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"Generate embeddings using built-in Elasticsearch ML\",
      \"processors\": [
        {
          \"set\": {
            \"field\": \"embedding_strategy\",
            \"value\": \"builtin\"
          }
        },
        {
          \"set\": {
            \"field\": \"embedding_model\",
            \"value\": \"$model_name\"
          }
        },
        {
          \"script\": {
            \"description\": \"Prepare content for embedding\",
            \"source\": \"if (ctx.name != null && ctx.email != null) { ctx.content_for_embedding = ctx.name + ' ' + ctx.email; } else if (ctx.name != null) { ctx.content_for_embedding = ctx.name; } else { ctx.content_for_embedding = ctx.email != null ? ctx.email : ''; }\"
          }
        },
        {
          \"inference\": {
            \"model_id\": \"$model_name\",
            \"input_output\": [
              {
                \"input_field\": \"content_for_embedding\",
                \"output_field\": \"content_embedding\"
              }
            ]
          }
        }
      ]
    }" > /dev/null
    
    echo "✅ Built-in ML pipeline configured"
}

# Function to setup external API pipeline (OpenAI, HuggingFace)
setup_external_api() {
    local strategy=$1
    local api_key_var=""
    local model_var=""
    local dims_var=""
    local url=""
    
    case $strategy in
        "openai")
            api_key_var="$OPENAI_API_KEY"
            model_var="$OPENAI_MODEL"
            dims_var="$OPENAI_DIMS"
            url="https://api.openai.com/v1/embeddings"
            ;;
        "huggingface")
            api_key_var="$HUGGINGFACE_API_KEY"
            model_var="$HUGGINGFACE_MODEL"
            dims_var="$HUGGINGFACE_DIMS"
            url="https://api-inference.huggingface.co/pipeline/feature-extraction/$model_var"
            ;;
    esac
    
    echo "🌐 Setting up external API pipeline for: $strategy"
    
    # Create pipeline that will be processed by Logstash (not ingest pipeline)
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_ingest/pipeline/vector_embeddings" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"Placeholder pipeline - embeddings generated in Logstash for $strategy\",
      \"processors\": [
        {
          \"set\": {
            \"field\": \"embedding_strategy\",
            \"value\": \"$strategy\"
          }
        },
        {
          \"set\": {
            \"field\": \"embedding_model\",
            \"value\": \"$model_var\"
          }
        },
        {
          \"script\": {
            \"description\": \"Prepare content for embedding\",
            \"source\": \"if (ctx.name != null && ctx.email != null) { ctx.content_for_embedding = ctx.name + ' ' + ctx.email; } else if (ctx.name != null) { ctx.content_for_embedding = ctx.name; } else { ctx.content_for_embedding = ctx.email != null ? ctx.email : ''; }\"
          }
        }
      ]
    }" > /dev/null
    
    echo "✅ External API pipeline configured (embeddings will be generated in Logstash)"
}

# Function to setup local embedding service
setup_local_service() {
    echo "🏠 Setting up local embedding service pipeline"
    
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_ingest/pipeline/vector_embeddings" \
    -H "Content-Type: application/json" \
    -d "{
      \"description\": \"Placeholder pipeline - embeddings generated via local service\",
      \"processors\": [
        {
          \"set\": {
            \"field\": \"embedding_strategy\",
            \"value\": \"local\"
          }
        },
        {
          \"set\": {
            \"field\": \"embedding_model\",
            \"value\": \"$LOCAL_EMBEDDING_MODEL\"
          }
        },
        {
          \"script\": {
            \"description\": \"Prepare content for embedding\",
            \"source\": \"if (ctx.name != null && ctx.email != null) { ctx.content_for_embedding = ctx.name + ' ' + ctx.email; } else if (ctx.name != null) { ctx.content_for_embedding = ctx.name; } else { ctx.content_for_embedding = ctx.email != null ? ctx.email : ''; }\"
          }
        }
      ]
    }" > /dev/null
    
    echo "✅ Local service pipeline configured"
}

# Function to disable vector search
setup_disabled() {
    echo "🚫 Setting up disabled vector search pipeline"
    
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_ingest/pipeline/vector_embeddings" \
    -H "Content-Type: application/json" \
    -d '{
      "description": "Vector search disabled",
      "processors": [
        {
          "set": {
            "field": "embedding_strategy",
            "value": "disabled"
          }
        },
        {
          "set": {
            "field": "embedding_note",
            "value": "Vector search is disabled"
          }
        }
      ]
    }' > /dev/null
    
    echo "✅ Vector search disabled"
}

# Setup based on strategy
case $STRATEGY in
    "builtin")
        setup_builtin_ml
        DIMS="${VECTOR_BUILTIN_DIMS:-384}"
        ;;
    "openai")
        setup_external_api "openai"
        DIMS="${OPENAI_DIMS:-1536}"
        ;;
    "huggingface")
        setup_external_api "huggingface"
        DIMS="${HUGGINGFACE_DIMS:-384}"
        ;;
    "local")
        setup_local_service
        DIMS="${LOCAL_EMBEDDING_DIMS:-384}"
        ;;
    "disabled")
        setup_disabled
        DIMS="0"
        ;;
    *)
        echo "❌ Unknown strategy: $STRATEGY"
        echo "Valid options: builtin, openai, huggingface, local, disabled"
        exit 1
        ;;
esac

# Create vector-enabled index template (only if not disabled)
if [ "$STRATEGY" != "disabled" ]; then
    echo "📋 Creating vector-enabled index template..."
    
    VECTOR_MAPPING=""
    if [ "$DIMS" != "0" ]; then
        VECTOR_MAPPING="\"content_embedding\": {
          \"type\": \"dense_vector\",
          \"dims\": $DIMS,
          \"index\": true,
          \"similarity\": \"${VECTOR_SIMILARITY_METRIC:-cosine}\"
        },"
    fi
    
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_index_template/${VECTOR_INDEX_PREFIX:-postgres-vector}" \
    -H "Content-Type: application/json" \
    -d "{
      \"index_patterns\": [\"${VECTOR_INDEX_PREFIX:-postgres-vector}-*\"],
      \"priority\": 400,
      \"template\": {
        \"settings\": {
          \"number_of_shards\": 1,
          \"number_of_replicas\": 0,
          \"default_pipeline\": \"vector_embeddings\",
          \"index\": {
            \"refresh_interval\": \"1s\"
          }
        },
        \"mappings\": {
          \"properties\": {
            \"@timestamp\": { \"type\": \"date\" },
            \"id\": { \"type\": \"integer\" },
            \"name\": { 
              \"type\": \"text\",
              \"fields\": { \"keyword\": { \"type\": \"keyword\" } }
            },
            \"email\": {
              \"type\": \"text\", 
              \"fields\": { \"keyword\": { \"type\": \"keyword\" } }
            },
            \"content_for_embedding\": { \"type\": \"text\" },
            $VECTOR_MAPPING
            \"embedding_strategy\": { \"type\": \"keyword\" },
            \"embedding_model\": { \"type\": \"keyword\" },
            \"embedding_note\": { \"type\": \"text\" },
            \"created_at\": { \"type\": \"date\" },
            \"created_timestamp\": { \"type\": \"date\" },
            \"data_source\": { \"type\": \"keyword\" },
            \"ingestion_timestamp\": { \"type\": \"date\" },
            \"table_name\": { \"type\": \"keyword\" },
            \"environment\": { \"type\": \"keyword\" }
          }
        }
      }
    }" > /dev/null
else
    echo "📋 Creating standard index template (no vectors)..."
    
    curl -s -k -u ${ELASTIC_USER}:${ELASTIC_PASS} -X PUT "${ELASTIC_URL}/_index_template/${VECTOR_INDEX_PREFIX:-postgres-vector}" \
    -H "Content-Type: application/json" \
    -d "{
      \"index_patterns\": [\"${VECTOR_INDEX_PREFIX:-postgres-vector}-*\"],
      \"priority\": 400,
      \"template\": {
        \"settings\": {
          \"number_of_shards\": 1,
          \"number_of_replicas\": 0,
          \"default_pipeline\": \"vector_embeddings\"
        },
        \"mappings\": {
          \"properties\": {
            \"@timestamp\": { \"type\": \"date\" },
            \"id\": { \"type\": \"integer\" },
            \"name\": { 
              \"type\": \"text\",
              \"fields\": { \"keyword\": { \"type\": \"keyword\" } }
            },
            \"email\": {
              \"type\": \"text\", 
              \"fields\": { \"keyword\": { \"type\": \"keyword\" } }
            },
            \"embedding_strategy\": { \"type\": \"keyword\" },
            \"embedding_note\": { \"type\": \"text\" },
            \"data_source\": { \"type\": \"keyword\" }
          }
        }
      }
    }" > /dev/null
fi

echo ""
echo "🎉 Vector Search Configuration Complete!"
echo ""
echo "📊 Configuration Summary:"
echo "   Strategy: $STRATEGY"
echo "   Index Pattern: ${VECTOR_INDEX_PREFIX:-postgres-vector}-*"
echo "   Vector Dimensions: $DIMS"
echo "   Similarity Metric: ${VECTOR_SIMILARITY_METRIC:-cosine}"
echo ""
echo "🔧 Next Steps:"
echo "   1. Update Logstash configuration to use ${VECTOR_INDEX_PREFIX:-postgres-vector}-* indices"
echo "   2. Restart the stack to apply changes"
echo "   3. Test with sample data"
echo ""
echo "💡 To change strategy:"
echo "   1. Update VECTOR_EMBEDDING_STRATEGY in .env file"  
echo "   2. Run this script again"
echo "   3. Restart logstash-postgres service"
