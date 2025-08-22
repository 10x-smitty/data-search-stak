# Practical Search Examples on Reconciliation Indices

## Overview
You **DO NOT need separate indices** for different search strategies. The same `reconciliation-*` indices support all search types because each document contains multiple searchable fields optimized for different purposes.

## Sample Data Structure in Index

```json
{
  "_index": "reconciliation-music-catalog-2025.01",
  "_source": {
    "song_title": "Love Me Tender",
    "artist": "Elvis Presley", 
    "writer": "Elvis Presley",
    "ipi_number": "123456789",
    "data_source": "ascap.csv",
    "source_system": "csv",
    
    // Multi-purpose search fields:
    "searchable_content": "Song Title: Love Me Tender. Artist: Elvis Presley. Writer: Elvis Presley. IPI Number: 123456789",
    "normalized_content": "song title: love me tender. artist: elvis presley. writer: elvis presley. ipi number: 123456789",
    "key_identifiers": "ipi_number: 123456789",
    "content_vector": [0.123, 0.456, 0.789, ...], // 384-dimensional vector
    
    // Enhanced fields:
    "artist_normalized": "Elvis Presley",
    "ipi_number_codes": ["123456789"]
  }
}
```

## Search Strategy Examples

### 1. 🎯 **Vector Semantic Search** (Reconciliation)
**Use Case**: Find similar songs even with different spelling/formatting

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "knn": {
      "field": "content_vector",
      "query_vector_builder": {
        "text_embedding": {
          "model_id": ".elser_model_2",
          "model_text": "Love Me Tender Elvis Presley songwriter"
        }
      },
      "k": 10
    }
  }'
```

**Finds**:
- "Love Me Tender" by Elvis Presley ✅
- "Lv Me Tender" by E. Presley ✅ (typos)
- "Love Me Tender (Remastered)" by Elvis ✅ (extra info)
- "Presley, Elvis - Love Me Tender" ✅ (different format)

---

### 2. 🔍 **Traditional Text Search** (Keyword)
**Use Case**: Standard search for specific terms

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "query": {
      "multi_match": {
        "query": "Elvis Presley Love Me Tender",
        "fields": ["searchable_content", "normalized_content"]
      }
    }
  }'
```

**Finds**:
- Records with "Elvis", "Presley", "Love", "Me", "Tender"
- Ranked by BM25 relevance score

---

### 3. 🎯 **Exact Field Search** (Structured)
**Use Case**: Precise filtering by specific criteria

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "query": {
      "bool": {
        "must": [
          {"term": {"artist.keyword": "Elvis Presley"}},
          {"term": {"data_source": "ascap.csv"}}
        ]
      }
    }
  }'
```

**Finds**:
- Only exact matches for "Elvis Presley" from ASCAP source

---

### 4. 🔄 **Fuzzy Text Search** (Typo Tolerance)
**Use Case**: Handle typos and minor spelling errors

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "query": {
      "multi_match": {
        "query": "Elvis Presly Lov Me Tendr",
        "fields": ["searchable_content", "artist", "song_title"],
        "fuzziness": "AUTO"
      }
    }
  }'
```

**Finds**:
- "Elvis Presley Love Me Tender" (corrects typos)
- Other Elvis Presley songs

---

### 5. 🔍 **Cross-Source Reconciliation** 
**Use Case**: Find matching records across different sources

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "query": {
      "bool": {
        "must": [
          {
            "knn": {
              "field": "content_vector", 
              "query_vector_builder": {
                "text_embedding": {
                  "model_text": "Love Me Tender Elvis Presley songwriter"
                }
              },
              "k": 20
            }
          }
        ],
        "must_not": [
          {"term": {"data_source": "ascap.csv"}}
        ]
      }
    }
  }'
```

**Finds**:
- Similar songs from BMI, SESAC (but NOT ASCAP)
- Perfect for finding the same song across different PROs

---

### 6. 📊 **Analytics/Aggregations**
**Use Case**: Data analysis and statistics

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "size": 0,
    "aggs": {
      "by_source": {
        "terms": {"field": "data_source.keyword"}
      },
      "by_artist": {
        "terms": {"field": "artist.keyword", "size": 10}
      }
    }
  }'
```

**Results**:
- Count of records per source (ASCAP: 10,000, BMI: 8,500, etc.)
- Top artists by record count

---

### 7. 🚀 **Hybrid Combined Search** (Best of All)
**Use Case**: Comprehensive search combining multiple strategies

```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "query": {
      "bool": {
        "should": [
          {
            "knn": {
              "field": "content_vector",
              "query_vector_builder": {
                "text_embedding": {
                  "model_text": "Love Me Tender Elvis Presley"
                }
              },
              "k": 5,
              "boost": 2.0
            }
          },
          {
            "multi_match": {
              "query": "Love Me Tender Elvis",
              "fields": ["searchable_content^1.5", "normalized_content"],
              "fuzziness": "AUTO",
              "boost": 1.0
            }
          },
          {
            "term": {
              "key_identifiers": {
                "value": "123456789",
                "boost": 3.0
              }
            }
          }
        ],
        "minimum_should_match": 1
      }
    }
  }'
```

**Result**: Best combination of semantic similarity + text relevance + exact IPI match

---

## Key Benefits

### ✅ **Single Index Architecture**
- One index supports ALL search types
- No need for separate indices
- Consistent data across all search strategies

### ✅ **Multi-Purpose Fields**
- `searchable_content`: Human-readable, good for traditional search
- `normalized_content`: Cleaned for fuzzy matching  
- `key_identifiers`: Exact values for precise matching
- `content_vector`: Semantic embeddings for similarity
- Original fields: Exact field-based queries

### ✅ **Source Flexibility**
- Same search strategies work on PostgreSQL records
- Same search strategies work on CSV records  
- Same search strategies work across sources
- Filter by source when needed

### ✅ **Performance Optimized**
- Vector similarity: Fast ANN (Approximate Nearest Neighbor)
- Text search: Optimized inverted indices
- Exact matching: Keyword fields
- Aggregations: Efficient bucketing

## Recommendation

**Start with ONE reconciliation index pattern** (`reconciliation-*`) and use different query strategies based on your use case:

- **Reconciliation/Deduplication**: Vector similarity
- **User Search Interface**: Hybrid (vector + text)
- **Data Filtering**: Exact field queries  
- **Analytics/Reporting**: Aggregations
- **Cross-Source Matching**: Vector + source filtering

You get maximum flexibility with minimum complexity!
