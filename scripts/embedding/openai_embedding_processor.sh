#!/bin/bash

# OpenAI Embedding Processor for Elasticsearch
# Monitors Elasticsearch for documents needing embeddings and processes them using OpenAI API

set -euo pipefail

# Configuration from environment variables
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
OPENAI_MODEL="${OPENAI_MODEL:-text-embedding-3-small}"
OPENAI_DIMS="${OPENAI_DIMS:-1536}"

ELASTIC_HOST="${ELASTIC_HOST:-https://localhost:9200}"
ELASTIC_USER="${ELASTIC_USER:-elastic}"
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-password}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

error() {
    log "ERROR: $1" >&2
}

info() {
    log "INFO: $1"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        error "Please install them with: brew install ${missing_deps[*]}"
        exit 1
    fi
}

# Test connections
test_connections() {
    info "Testing connections..."
    
    # Test Elasticsearch connection
    local es_response
    es_response=$(curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" "${ELASTIC_HOST}")
    if ! echo "$es_response" | jq -e '.version.number' >/dev/null 2>&1; then
        error "Failed to connect to Elasticsearch at ${ELASTIC_HOST}"
        error "Response: $es_response"
        exit 1
    fi
    
    local es_version
    es_version=$(echo "$es_response" | jq -r '.version.number')
    info "Connected to Elasticsearch: $es_version"
    
    # Test OpenAI API connection
    local openai_response
    openai_response=$(curl -s -X POST https://api.openai.com/v1/embeddings \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "'"$OPENAI_MODEL"'",
            "input": "test connection"
        }')
    
    if ! echo "$openai_response" | jq -e '.data[0].embedding' >/dev/null 2>&1; then
        error "Failed to connect to OpenAI API"
        error "Response: $openai_response"
        exit 1
    fi
    
    info "Connected to OpenAI API - Model: $OPENAI_MODEL"
}

# Find documents that need embeddings
get_documents_needing_embeddings() {
    local index_pattern="${1:-reconciliation-*}"
    local batch_size="${2:-10}"
    
    local query='{
        "query": {
            "bool": {
                "must": [
                    {"term": {"needs_embedding": true}},
                    {"exists": {"field": "searchable_content"}}
                ],
                "must_not": [
                    {"exists": {"field": "text_embedding"}}
                ]
            }
        },
        "size": '"$batch_size"'
    }'
    
    curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
        -X GET "${ELASTIC_HOST}/${index_pattern}/_search" \
        -H "Content-Type: application/json" \
        -d "$query"
}

# Generate OpenAI embedding for text
generate_embedding() {
    local text="$1"
    
    # Escape the text for JSON
    local escaped_text
    escaped_text=$(echo "$text" | jq -R .)
    
    local payload='{
        "model": "'"$OPENAI_MODEL"'",
        "input": '"$escaped_text"'
    }'
    
    curl -s -X POST https://api.openai.com/v1/embeddings \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload"
}

# Update document with embedding
update_document_with_embedding() {
    local doc_index="$1"
    local doc_id="$2"
    local embedding="$3"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    local update_payload='{
        "doc": {
            "text_embedding": '"$embedding"',
            "needs_embedding": false,
            "embedding_generated_at": "'"$timestamp"'",
            "embedding_model_used": "'"$OPENAI_MODEL"'",
            "embedding_status": "completed"
        }
    }'
    
    local response
    response=$(curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
        -X POST "${ELASTIC_HOST}/${doc_index}/_update/${doc_id}" \
        -H "Content-Type: application/json" \
        -d "$update_payload")
    
    if echo "$response" | jq -e '.result' >/dev/null 2>&1; then
        info "Updated document $doc_id with embedding"
        return 0
    else
        error "Failed to update document $doc_id"
        error "Response: $response"
        return 1
    fi
}

# Mark document as failed
mark_document_failed() {
    local doc_index="$1"
    local doc_id="$2"
    local error_msg="$3"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    local update_payload='{
        "doc": {
            "needs_embedding": false,
            "embedding_status": "failed",
            "embedding_error": "'"${error_msg//\"/\\\"}"'",
            "embedding_failed_at": "'"$timestamp"'"
        }
    }'
    
    curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
        -X POST "${ELASTIC_HOST}/${doc_index}/_update/${doc_id}" \
        -H "Content-Type: application/json" \
        -d "$update_payload" >/dev/null
}

# Process all pending embeddings
process_pending_embeddings() {
    info "Starting embedding processing..."
    
    local documents_response
    documents_response=$(get_documents_needing_embeddings)
    
    local total_hits
    total_hits=$(echo "$documents_response" | jq -r '.hits.total.value // 0')
    
    if [ "$total_hits" -eq 0 ]; then
        info "No documents need embeddings"
        return 0
    fi
    
    info "Processing $total_hits documents for embeddings"
    
    local processed=0
    
    # Process each document
    echo "$documents_response" | jq -r '.hits.hits[] | @base64' | while read -r encoded_hit; do
        local hit
        hit=$(echo "$encoded_hit" | base64 --decode)
        
        local doc_index doc_id searchable_content
        doc_index=$(echo "$hit" | jq -r '._index')
        doc_id=$(echo "$hit" | jq -r '._id')
        searchable_content=$(echo "$hit" | jq -r '._source.searchable_content // ""')
        
        if [ -z "$searchable_content" ]; then
            error "Document $doc_id has no searchable_content"
            continue
        fi
        
        info "Generating embedding for document: $doc_id"
        info "Content preview: ${searchable_content:0:100}..."
        
        # Generate embedding
        local embedding_response
        embedding_response=$(generate_embedding "$searchable_content")
        
        if echo "$embedding_response" | jq -e '.data[0].embedding' >/dev/null 2>&1; then
            local embedding
            embedding=$(echo "$embedding_response" | jq '.data[0].embedding')
            
            # Truncate embedding to specified dimensions if needed
            if [ "$OPENAI_DIMS" != "1536" ]; then
                embedding=$(echo "$embedding" | jq ".[0:$OPENAI_DIMS]")
                info "Truncated embedding from 1536 to $OPENAI_DIMS dimensions"
            fi
            
            # Update document
            if update_document_with_embedding "$doc_index" "$doc_id" "$embedding"; then
                ((processed++))
            else
                mark_document_failed "$doc_index" "$doc_id" "Failed to update document"
            fi
        else
            local error_msg
            error_msg=$(echo "$embedding_response" | jq -r '.error.message // "Unknown error"')
            error "Failed to generate embedding for document $doc_id: $error_msg"
            mark_document_failed "$doc_index" "$doc_id" "$error_msg"
        fi
        
        # Rate limiting - OpenAI has rate limits
        sleep 0.5
    done
    
    info "Processed $processed documents"
    return 0
}

# Run continuous processing
run_continuous() {
    local interval_seconds="${1:-30}"
    
    info "Starting continuous embedding processor (interval: ${interval_seconds}s)"
    
    while true; do
        process_pending_embeddings || true
        
        info "Waiting ${interval_seconds} seconds before next run..."
        sleep "$interval_seconds"
    done
}

# Main function
main() {
    # Validate required environment variables
    if [ -z "$OPENAI_API_KEY" ]; then
        error "OPENAI_API_KEY environment variable is required"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Test connections
    test_connections
    
    # Parse command line arguments
    case "${1:-}" in
        --continuous)
            local interval="${2:-30}"
            run_continuous "$interval"
            ;;
        --help|-h)
            echo "Usage: $0 [--continuous [interval]] [--help]"
            echo ""
            echo "Options:"
            echo "  --continuous [interval]  Run continuous processing (default interval: 30s)"
            echo "  --help, -h              Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  OPENAI_API_KEY          OpenAI API key (required)"
            echo "  OPENAI_MODEL            OpenAI model (default: text-embedding-3-small)"
            echo "  OPENAI_DIMS             Embedding dimensions (default: 1536)"
            echo "  ELASTIC_HOST            Elasticsearch host (default: https://localhost:9200)"
            echo "  ELASTIC_USER            Elasticsearch user (default: elastic)"
            echo "  ELASTIC_PASSWORD        Elasticsearch password (default: password)"
            exit 0
            ;;
        "")
            # Run once
            process_pending_embeddings
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
