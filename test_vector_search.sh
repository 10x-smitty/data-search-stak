#!/bin/bash

# Test vector similarity search for music rights reconciliation
# This script demonstrates how to perform semantic search using OpenAI embeddings

set -euo pipefail

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Set defaults for required variables
ELASTIC_HOST="${ELASTIC_HOST:-https://localhost:9200}"
ELASTIC_USER="${ELASTIC_USER:-elastic}"
ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-password}"

# Function to generate embedding for search query
generate_query_embedding() {
    local query="$1"
    local escaped_query
    escaped_query=$(echo "$query" | jq -R .)
    
    local payload='{
        "model": "'"$OPENAI_MODEL"'",
        "input": '"$escaped_query"'
    }'
    
    curl -s -X POST https://api.openai.com/v1/embeddings \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload" | jq '.data[0].embedding'
}

# Function to perform vector similarity search
vector_search() {
    local query="$1"
    local k="${2:-5}"
    
    echo "Generating embedding for query: '$query'"
    local query_embedding
    query_embedding=$(generate_query_embedding "$query")
    
    if [ "$query_embedding" == "null" ]; then
        echo "Failed to generate embedding for query"
        return 1
    fi
    
    echo "Performing vector similarity search (k=$k)..."
    
    local search_payload='{
        "knn": {
            "field": "text_embedding",
            "query_vector": '"$query_embedding"',
            "k": '"$k"',
            "num_candidates": 100
        },
        "_source": [
            "title",
            "writers",
            "publishers", 
            "genre",
            "iswc",
            "data_source",
            "searchable_content"
        ]
    }'
    
    curl -s -k -u "${ELASTIC_USER}:${ELASTIC_PASSWORD}" \
        -X POST "${ELASTIC_HOST}/reconciliation-*/_search" \
        -H "Content-Type: application/json" \
        -d "$search_payload"
}

# Function to format search results
format_results() {
    local response="$1"
    
    echo "=== VECTOR SIMILARITY SEARCH RESULTS ==="
    echo ""
    
    local total_hits
    total_hits=$(echo "$response" | jq -r '.hits.total.value // 0')
    
    if [ "$total_hits" -eq 0 ]; then
        echo "No results found"
        return
    fi
    
    echo "Found $total_hits matches:"
    echo ""
    
    echo "$response" | jq -r '
        .hits.hits[] | 
        "Score: " + (.score | tostring) + 
        "\nTitle: " + ._source.title + 
        "\nWriters: " + ._source.writers + 
        "\nPublishers: " + ._source.publishers + 
        "\nGenre: " + ._source.genre + 
        "\nISWC: " + ._source.iswc + 
        "\nSource: " + ._source.data_source + 
        "\n" + ("=" * 50) + "\n"
    '
}

# Main function
main() {
    echo "Music Rights Vector Similarity Search Test"
    echo "=========================================="
    echo ""
    
    # Test queries for music rights reconciliation
    local test_queries=(
        "Beatles song written by John Lennon and Paul McCartney"
        "Pop song by Taylor Swift"
        "Rock ballad by Diane Warren"
        "Beyonce R&B track"
        "Ed Sheeran pop hit"
    )
    
    if [ $# -gt 0 ]; then
        # Use provided query
        local query="$1"
        local k="${2:-5}"
        
        local response
        response=$(vector_search "$query" "$k")
        format_results "$response"
    else
        # Run all test queries
        for query in "${test_queries[@]}"; do
            echo "Testing query: '$query'"
            echo "------------------------------"
            
            local response
            response=$(vector_search "$query" 3)
            
            if echo "$response" | jq -e '.hits.hits[0]' >/dev/null 2>&1; then
                echo "✅ Found matches for: '$query'"
                format_results "$response"
                echo ""
            else
                echo "❌ No matches found for: '$query'"
                echo ""
            fi
            
            sleep 1  # Rate limiting
        done
    fi
}

# Show help
if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
    echo "Usage: $0 [query] [k]"
    echo ""
    echo "Examples:"
    echo "  $0                                           # Run all test queries"
    echo "  $0 \"Beatles song by Lennon McCartney\"        # Search for specific query"
    echo "  $0 \"Taylor Swift pop song\" 10                # Search with k=10 results"
    echo ""
    exit 0
fi

main "$@"
