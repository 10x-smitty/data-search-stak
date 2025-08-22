# Music Rights Data Reconciliation System

## 🎵 What We've Built

A complete **music publishing rights data reconciliation system** that demonstrates cross-source vector search capabilities. Perfect for testing "fuzzy matching on steroids" across different PRO (Performance Rights Organization) data sources.

## 📊 Sample Data Included

### PostgreSQL Database (Complete Music Rights Schema)
- **Writers**: 10 famous songwriters with IPI numbers, PRO affiliations
- **Publishers**: 10 major music publishers (Sony/ATV, Universal, Warner Chappell, etc.)
- **Songs**: 12 hit songs with alternate titles and ISWC codes
- **Relationships**: Writer-song and publisher-song mappings with ownership percentages
- **Rights Tracking**: Performance and mechanical rights data
- **View**: `songs_complete` - Comprehensive song information for reconciliation

### CSV Files (PRO Catalog Exports)
- **ASCAP_Catalog_Export.csv**: 15 records from ASCAP
- **BMI_Catalog_Export.csv**: 15 records from BMI with different formatting
- **SESAC_Catalog_Export.csv**: 15 records from SESAC with variations

### Data Variations (Perfect for Testing Reconciliation)
- **Name Formats**: "John Lennon" vs "Lennon, John" vs "J. Lennon"
- **Title Variations**: "Hey Jude" vs "Hey Jude (Remastered)" vs "Hey Jude - 2018 Mix"
- **Publisher Names**: "Sony/ATV Music Publishing" vs "Sony ATV Music" vs "Sony ATV Publishing"
- **Missing Data**: Some records missing IPI numbers, some missing writers
- **Field Differences**: Different column names across sources

## 🏗️ System Architecture

### Data Processing Pipeline
```
PostgreSQL (music_rights schema)
├── songs_complete view
├── Logstash JDBC (logstash-postgres-reconciliation.conf)
├── Vector embeddings generation
└── reconciliation-postgresql-music-rights-* indices

CSV Files (ASCAP/BMI/SESAC)
├── Auto-detected column parsing
├── Logstash CSV (logstash-csv-reconciliation.conf) 
├── Vector embeddings generation
└── reconciliation-*.csv-* indices
```

### Search Capabilities
- **Vector Similarity**: Find semantically similar songs across sources
- **Traditional Text**: Keyword-based search with BM25 scoring
- **Fuzzy Matching**: Handle typos and variations with fuzziness
- **Exact Matching**: Precise IPI number and code matching
- **Cross-Source**: Match records between PostgreSQL and CSV sources
- **Hybrid Queries**: Combine multiple search strategies

## 🎯 Real-World Reconciliation Examples

### Example 1: Cross-PRO Song Matching
**Database Record** (PostgreSQL):
```json
{
  "title": "Hey Jude",
  "writers": "John Lennon (IPI: 00014107338), Paul McCartney (IPI: 00026239279)",
  "publishers": "Sony/ATV Music Publishing (IPI: 00026955529)",
  "source_system": "postgresql"
}
```

**CSV Record** (BMI Export):
```json
{
  "Song_Title": "Hey Jude - 2018 Mix", 
  "Composer_Name": "Lennon John",
  "Composer_IPI_Number": "00014107338",
  "Publishing_Company": "Sony ATV Music",
  "data_source": "BMI_Catalog_Export.csv"
}
```

**Vector Search Result**: ✅ **High similarity match** despite:
- Different title format ("Hey Jude" vs "Hey Jude - 2018 Mix")
- Name order variation ("John Lennon" vs "Lennon John")
- Publisher name difference ("Sony/ATV Music Publishing" vs "Sony ATV Music")
- Same IPI number provides exact confirmation

### Example 2: Missing Data Reconciliation
**ASCAP Record**:
```json
{
  "Title": "Shake It Off",
  "Writer_Name": "Taylor Swift",
  "Writer_IPI": "00450016959",
  "Publisher_Name": "Taylor Swift Music"
}
```

**SESAC Record**:
```json
{
  "Work_Title": "Shake It Off - Radio Edit",
  "Author_Name": "T. Swift", 
  "Author_IPI": "00450016959",
  "Publisher_Entity": "Taylor Swift Music LLC"
}
```

**Vector Search Result**: ✅ **Strong match** despite:
- Name abbreviation ("Taylor Swift" vs "T. Swift")
- Title variation ("Shake It Off" vs "Shake It Off - Radio Edit")
- Publisher variation ("Taylor Swift Music" vs "Taylor Swift Music LLC")
- IPI number confirms it's the same person

## 🔍 Query Examples

### Find Similar Songs Across All Sources
```bash
curl -X GET "https://localhost:9200/reconciliation-*/_search" \
  -H "Content-Type: application/json" \
  -u elastic:password -k \
  -d '{
    "knn": {
      "field": "content_vector",
      "query_vector_builder": {
        "text_embedding": {
          "model_text": "Blinding Lights The Weeknd Abel Tesfaye"
        }
      },
      "k": 10
    }
  }'
```

### Cross-Source Reconciliation (Find CSV matches for PostgreSQL record)
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
                  "model_text": "Yesterday Paul McCartney Beatles Sony"
                }
              },
              "k": 20
            }
          }
        ],
        "must_not": [
          {"term": {"source_system": "postgresql"}}
        ]
      }
    }
  }'
```

## 🚀 Getting Started

1. **Start the Stack**:
   ```bash
   docker-compose up -d
   ```

2. **Apply Index Template**:
   ```bash
   curl -X PUT "https://localhost:9200/_index_template/reconciliation" \
     -H "Content-Type: application/json" \
     -u elastic:password -k \
     -d @elasticsearch-templates/reconciliation-template.json
   ```

3. **Wait for Data Loading** (2-3 minutes):
   - PostgreSQL schema and data loads automatically
   - CSV files are processed by Logstash
   - Vector embeddings are generated

4. **Test Reconciliation**:
   - Use queries from `reconciliation-queries.json`
   - Use queries from `cross-source-reconciliation-queries.json`
   - Or browse data in Kibana at http://localhost:5601

## 📈 Expected Results

After setup, you'll have:
- **~40+ documents** indexed across all sources
- **Vector embeddings** for semantic similarity
- **Cross-source matching** capabilities
- **Multiple search strategies** on the same data
- **Real-world reconciliation scenarios** ready for testing

## 🎓 Use Cases

This setup demonstrates solutions for:
- **Music Rights Management**: Reconcile catalogs across PROs
- **Customer Data Deduplication**: Find duplicate customers across systems
- **Product Catalog Matching**: Match products across vendors
- **Financial Record Reconciliation**: Match transactions across sources
- **Any data matching scenario** where exact matches aren't possible

The system showcases how vector search can handle real-world data challenges like typos, formatting differences, missing information, and semantic variations that traditional matching systems struggle with.
