#!/bin/bash

# Startup script to preserve embeddings during system restarts
# This script should be run after Docker services start

set -euo pipefail

# Configuration from environment variables
ELASTIC_HOST="${ELASTIC_HOST:-https://localhost:9200}"
ELASTIC_USER="${ELASTIC_USER:-elastic}"
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-password}"

echo "🎵 Music Rights Embedding Preservation & Processing"
echo "=================================================="
echo ""

# Wait for Elasticsearch to be ready
wait_for_elasticsearch() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Waiting for Elasticsearch to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" "${ELASTIC_HOST}/_cluster/health" >/dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Elasticsearch is ready!"
            return 0
        fi
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Attempt $attempt/$max_attempts - Elasticsearch not ready yet..."
        sleep 5
        ((attempt++))
    done
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Elasticsearch not ready after $max_attempts attempts"
    return 1
}

# Wait for documents to be indexed
wait_for_documents() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Waiting for documents to be indexed..."
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local doc_count
        doc_count=$(curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
            "${ELASTIC_HOST}/reconciliation-*/_count" 2>/dev/null | jq -r '.count // 0' 2>/dev/null || echo "0")
        
        if [ "$doc_count" -gt 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Found $doc_count documents indexed"
            return 0
        fi
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Attempt $attempt/$max_attempts - No documents found yet..."
        sleep 10
        ((attempt++))
    done
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: No documents found after waiting"
    return 1
}

# Main function
main() {
    # Step 1: Wait for services
    if ! wait_for_elasticsearch; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to connect to Elasticsearch"
        exit 1
    fi
    
    # Step 2: Wait for initial data ingestion
    if wait_for_documents; then
        echo ""
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting embedding preservation process..."
        
        # Step 3: Preserve existing embeddings (flag only documents without embeddings)
        if ./preserve_embeddings.sh; then
            echo ""
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Starting embedding processor..."
            
            # Step 4: Generate embeddings for flagged documents
            if ./openai_embedding_processor.sh; then
                echo ""
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ SUCCESS: Embedding preservation and processing complete!"
                
                # Show final status
                local embedded_count
                embedded_count=$(curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
                    "${ELASTIC_HOST}/reconciliation-*/_search" \
                    -H "Content-Type: application/json" \
                    -d '{"query":{"exists":{"field":"text_embedding"}},"size":0}' | \
                    jq -r '.hits.total.value // 0')
                
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Total documents with embeddings: $embedded_count"
                return 0
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERROR: Embedding processor failed"
                return 1
            fi
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERROR: Embedding preservation failed"
            return 1
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: No documents to process"
    fi
}

# Help message
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "This script preserves embeddings during system restarts by:"
    echo "1. Waiting for Elasticsearch to be ready"
    echo "2. Waiting for documents to be indexed by Logstash"
    echo "3. Flagging only documents that need embeddings (preserves existing ones)"
    echo "4. Running the embedding processor to generate missing vectors"
    echo ""
    echo "Environment Variables:"
    echo "  ELASTIC_HOST     - Elasticsearch host (default: https://localhost:9200)"
    echo "  ELASTIC_USER     - Elasticsearch user (default: elastic)"
    echo "  ELASTIC_PASSWORD - Elasticsearch password"
    echo ""
    exit 0
fi

# Run main function
main "$@"
