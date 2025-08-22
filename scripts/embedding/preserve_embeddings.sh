#!/bin/bash

# Script to preserve embeddings during data ingestion
# Only flags documents that don't already have embeddings

set -euo pipefail

# Configuration from environment variables
ELASTIC_HOST="${ELASTIC_HOST:-https://localhost:9200}"
ELASTIC_USER="${ELASTIC_USER:-elastic}"
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-password}"

# Function to flag only documents without embeddings
flag_documents_needing_embeddings() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Flagging documents that need embeddings (preserving existing ones)"
    
    # Query to find documents WITHOUT text_embedding field
    local query='{
        "query": {
            "bool": {
                "must_not": [
                    {"exists": {"field": "text_embedding"}}
                ]
            }
        },
        "script": {
            "source": "ctx._source.needs_embedding = true; ctx._source.embedding_status = \"pending\";"
        }
    }'
    
    local response
    response=$(curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
        -X POST "${ELASTIC_HOST}/reconciliation-*/_update_by_query" \
        -H "Content-Type: application/json" \
        -d "$query")
    
    local updated
    updated=$(echo "$response" | jq -r '.updated // 0')
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Flagged $updated documents for embedding processing"
    return 0
}

# Main function
main() {
    flag_documents_needing_embeddings
}

# Run if called directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
