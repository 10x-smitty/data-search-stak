#!/bin/bash

# Setup Elasticsearch index templates for PostgreSQL data
# Run this after the stack is up and running

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s -k -u elastic:${ELASTIC_PASSWORD:-password} https://localhost:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

echo "Creating index template for PostgreSQL users..."

# Create index template for users data
curl -k -u elastic:${ELASTIC_PASSWORD:-password} -X PUT "https://localhost:9200/_index_template/postgres-users" \
-H "Content-Type: application/json" \
-d '{
  "index_patterns": ["postgres-users-*"],
  "priority": 200,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
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
        "created_at": { "type": "date" },
        "created_timestamp": { "type": "date" },
        "data_source": { "type": "keyword" },
        "ingestion_timestamp": { "type": "date" }
      }
    }
  }
}'

echo "Creating index template for PostgreSQL graph data..."

# Create index template for graph data  
curl -k -u elastic:${ELASTIC_PASSWORD:-password} -X PUT "https://localhost:9200/_index_template/postgres-graph" \
-H "Content-Type: application/json" \
-d '{
  "index_patterns": ["postgres-graph-*"],
  "priority": 200,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "graph_node_id": { "type": "long" },
        "graph_labels": { "type": "keyword" },
        "properties": { "type": "object" },
        "data_source": { "type": "keyword" },
        "ingestion_timestamp": { "type": "date" }
      }
    }
  }
}'

echo "Index templates created successfully!"

# Check if data is being indexed
echo "Checking for indexed data..."
sleep 10

echo "Users index:"
curl -k -s -u elastic:${ELASTIC_PASSWORD:-password} "https://localhost:9200/postgres-users-*/_search?size=3&pretty"

echo "Graph index:"
curl -k -s -u elastic:${ELASTIC_PASSWORD:-password} "https://localhost:9200/postgres-graph-*/_search?size=3&pretty"
