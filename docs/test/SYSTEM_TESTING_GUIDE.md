# System Testing Guide

This document provides step-by-step instructions for testing all components of the Music Rights Reconciliation System after reorganization or deployment.

## 🎯 Overview

The Music Rights Reconciliation System consists of multiple integrated components:
- **Docker Compose** orchestration
- **PostgreSQL** database with music rights data
- **Logstash** data ingestion pipelines
- **Elasticsearch** indexing and search
- **OpenAI** vector embeddings
- **Custom scripts** for processing and testing

## 🧪 Test Categories

### 1. Infrastructure Tests
- Docker Compose configuration validation
- Service health checks
- File path verification

### 2. Data Pipeline Tests
- PostgreSQL connectivity and data
- Logstash ingestion verification
- Elasticsearch indexing validation

### 3. AI Integration Tests
- OpenAI API connectivity
- Vector embedding generation
- Search functionality validation

### 4. System Integration Tests
- End-to-end data flow
- Cross-service communication
- Performance verification

---

## 📋 Step-by-Step Testing Procedures

### Test 1: Docker Compose Configuration

**Purpose**: Verify all services start correctly with proper file paths

**Prerequisites**: 
- Docker and Docker Compose installed
- `.env` file configured with required variables

**Steps**:

1. **Validate Configuration Syntax**
   ```bash
   docker-compose config --quiet
   ```
   *Expected*: Command completes with exit code 0 (no output means success)

2. **Check Service Status**
   ```bash
   docker-compose ps
   ```
   *Expected*: All services show "Up" or "Up (healthy)" status
   
   Key services to verify:
   - `mdb-elastic-es01-1` (Elasticsearch)
   - `mdb-elastic-kibana-1` (Kibana)
   - `logstash-postgres` (PostgreSQL Logstash)
   - `postgres-age` (PostgreSQL database)
   - `mdb-elastic-filebeat01-1` (Filebeat)
   - `mdb-elastic-metricbeat01-1` (Metricbeat)

3. **Verify Critical File Paths**
   ```bash
   echo "=== Checking critical file paths ==="
   echo "Logstash configs:"
   ls -la logstash/*.conf
   echo -e "\nBeats configs:"
   ls -la filebeat/filebeat.yml metricbeat/metricbeat.yml
   echo -e "\nDrivers:"
   ls -la logstash/drivers/
   echo -e "\nPostgreSQL init scripts:"
   ls -la postgres/
   echo -e "\nEmbedding scripts:"
   ls -la scripts/embedding/
   ```
   *Expected*: All files exist in their specified locations

**Success Criteria**: ✅
- Configuration validates without errors
- All services are running
- All required files are accessible

---

### Test 2: PostgreSQL Integration

**Purpose**: Verify database connectivity and music rights data availability

**Steps**:

1. **Test Database Connection**
   ```bash
   export $(grep -v '^#' .env | xargs)
   docker exec postgres-age psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT version();"
   ```
   *Expected*: PostgreSQL version information displayed

2. **Verify Data Schema**
   ```bash
   docker exec postgres-age psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\dt"
   ```
   *Expected*: Tables listed including `songs`, `writers`, `publishers`, etc.

3. **Check Record Count**
   ```bash
   docker exec postgres-age psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT COUNT(*) as song_count FROM songs;"
   ```
   *Expected*: Should show 12 songs

4. **Sample Data Verification**
   ```bash
   docker exec postgres-age psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT title, writers FROM songs_complete LIMIT 3;"
   ```
   *Expected*: Sample output showing songs like "Hey Jude", "Yesterday", etc.

**Success Criteria**: ✅
- Database connection successful
- All tables exist
- Expected number of records present
- Sample data shows correct structure

---

### Test 3: Logstash Data Pipeline

**Purpose**: Verify Logstash is successfully ingesting PostgreSQL data

**Steps**:

1. **Check Logstash PostgreSQL Service Logs**
   ```bash
   docker logs logstash-postgres --tail 10
   ```
   *Expected*: Recent log entries showing "POSTGRES:" debug output with song processing

2. **Monitor Real-time Processing**
   ```bash
   docker logs logstash-postgres --tail 5 --follow
   ```
   *Expected*: Continuous processing every 2 minutes (per schedule)
   *Note*: Press Ctrl+C to stop monitoring

3. **Verify Logstash Health**
   ```bash
   curl -s http://localhost:9600/_node/stats/pipeline | jq '.pipeline.events'
   ```
   *Expected*: Statistics showing events processed

**Success Criteria**: ✅
- Logstash logs show successful PostgreSQL connections
- Debug output displays processed songs
- Pipeline statistics indicate active processing

---

### Test 4: Elasticsearch Indexing

**Purpose**: Verify data is properly indexed and searchable in Elasticsearch

**Steps**:

1. **Check Reconciliation Indices**
   ```bash
   curl -k -u "elastic:password" "https://localhost:9200/_cat/indices/reconciliation*?v"
   ```
   *Expected*: Index `reconciliation-postgresql-music-rights-YYYY.MM` exists with documents

2. **Verify Document Count**
   ```bash
   curl -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_count"
   ```
   *Expected*: `{"count":12,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}`

3. **Sample Data Retrieval**
   ```bash
   curl -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_search?size=2&pretty" | head -30
   ```
   *Expected*: JSON response with sample music rights documents

4. **Search Functionality Test**
   ```bash
   curl -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_search" \
     -H "Content-Type: application/json" \
     -d '{"query":{"match":{"title":"Hey Jude"}},"size":1}' | jq '.hits.total.value'
   ```
   *Expected*: Should return 1 or more matches

**Success Criteria**: ✅
- Reconciliation index exists and is healthy
- Expected document count (12) present
- Documents contain proper music rights metadata
- Search queries return relevant results

---

### Test 5: OpenAI Integration

**Purpose**: Verify OpenAI API connectivity and embedding generation

**Prerequisites**: 
- `OPENAI_API_KEY` configured in `.env` file
- Environment variables loaded

**Steps**:

1. **Load Environment and Test Embedding Script**
   ```bash
   cd scripts/embedding
   export $(grep -v '^#' ../../.env | xargs)
   ./openai_embedding_processor.sh
   ```
   *Expected*: 
   - "Connected to Elasticsearch" message
   - "Connected to OpenAI API" message
   - Processing messages for documents
   - "Updated document X with embedding" confirmations

2. **Verify Embedding Status**
   ```bash
   cd ../../
   curl -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_search?q=needs_embedding:false&size=0" | jq '.hits.total.value'
   ```
   *Expected*: Number indicating how many documents have been processed

3. **Check Specific Document for Embeddings**
   ```bash
   curl -k -u "elastic:password" "https://localhost:9200/reconciliation-postgresql-music-rights-*/postgres-music-rights-1" | jq '._source | {title, needs_embedding, embedding_status, has_text_embedding: (.text_embedding != null)}'
   ```
   *Expected*: Document with embedding metadata

**Success Criteria**: ✅
- OpenAI API connection successful
- Embedding processor runs without errors
- Documents are updated with vector embeddings
- Processing status properly tracked

---

### Test 6: Vector Search Functionality

**Purpose**: Verify vector similarity search is operational

**Steps**:

1. **Basic Search Test**
   ```bash
   export $(grep -v '^#' .env | xargs)
   ./scripts/testing/simple_vector_test.sh
   ```
   *Expected*: 
   - Beatles songs found (Hey Jude, Bohemian Rhapsody, Imagine)
   - Taylor Swift songs found (Shake It Off)
   - Document counts displayed
   - All searches return relevant results

2. **Advanced Vector Search Test** (if embeddings are working)
   ```bash
   ./scripts/testing/test_vector_search.sh "Beatles song written by John Lennon and Paul McCartney"
   ```
   *Expected*: Semantically similar results based on OpenAI embeddings

3. **Cross-Source Reconciliation Query**
   ```bash
   curl -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_search" \
     -H "Content-Type: application/json" \
     -d '{
       "query": {
         "bool": {
           "should": [
             {"match": {"writers": "John Lennon"}},
             {"match": {"writers": "Paul McCartney"}}
           ]
         }
       },
       "_source": ["title", "writers", "publishers", "genre"],
       "size": 3
     }' | jq '.hits.hits[]._source'
   ```
   *Expected*: Songs by Lennon/McCartney with metadata

**Success Criteria**: ✅
- Text-based searches return accurate results
- Vector embeddings enable semantic search
- Cross-source queries work across data types
- Search response times are reasonable

---

### Test 7: File Path and Reference Validation

**Purpose**: Ensure all moved files are accessible and scripts work from various locations

**Steps**:

1. **Verify Service Directory Structure**
   ```bash
   echo "Testing paths in Docker Compose:"
   echo "1. Logstash configs exist:"
   ls -la logstash/*.conf
   echo -e "\n2. Beat configs exist:"
   ls -la filebeat/filebeat.yml metricbeat/metricbeat.yml
   echo -e "\n3. PostgreSQL init files exist:"
   ls -la postgres/*.sql
   echo -e "\n4. Elasticsearch templates directory:"
   ls -la elasticsearch/templates/
   ```
   *Expected*: All files present in their expected service directories

2. **Test Script Execution from Root**
   ```bash
   ./scripts/testing/simple_vector_test.sh --help 2>/dev/null | head -3
   ```
   *Expected*: Help text or indication script is accessible

3. **Test Cross-Directory Dependencies**
   ```bash
   cd scripts/embedding
   ls -la ../../.env
   cd ../../
   ```
   *Expected*: Scripts can find dependencies across directory structure

**Success Criteria**: ✅
- All configuration files in correct service directories
- Scripts executable from project root
- Cross-directory references work properly
- No broken symbolic links or missing files

---

## 🎯 Comprehensive System Validation

### End-to-End Test

Run this complete test sequence to validate the entire system:

```bash
#!/bin/bash
echo "🎉 === COMPREHENSIVE SYSTEM TEST ==="
echo ""

# Test 1: Configuration
echo "✅ Testing Docker Compose Configuration..."
docker-compose config --quiet && echo "   PASSED" || echo "   FAILED"

# Test 2: Services
echo "✅ Testing Service Health..."
docker-compose ps | grep -q "Up" && echo "   PASSED" || echo "   FAILED"

# Test 3: Database
echo "✅ Testing PostgreSQL..."
export $(grep -v '^#' .env | xargs)
SONG_COUNT=$(docker exec postgres-age psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM songs;")
[ "$SONG_COUNT" -eq 12 ] && echo "   PASSED (12 songs)" || echo "   FAILED ($SONG_COUNT songs)"

# Test 4: Elasticsearch
echo "✅ Testing Elasticsearch..."
DOC_COUNT=$(curl -s -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_count" | jq -r '.count')
[ "$DOC_COUNT" -gt 0 ] && echo "   PASSED ($DOC_COUNT documents)" || echo "   FAILED (0 documents)"

# Test 5: OpenAI (if key available)
if [ ! -z "$OPENAI_API_KEY" ]; then
    echo "✅ Testing OpenAI Integration..."
    cd scripts/embedding && ./openai_embedding_processor.sh > /dev/null 2>&1 && echo "   PASSED" || echo "   NEEDS ATTENTION"
    cd ../../
else
    echo "⚠️  OpenAI test skipped (no API key)"
fi

# Test 6: Search
echo "✅ Testing Search Functionality..."
./scripts/testing/simple_vector_test.sh > /dev/null 2>&1 && echo "   PASSED" || echo "   NEEDS ATTENTION"

echo ""
echo "🎵 === SYSTEM VALIDATION COMPLETE ==="
```

### Expected Output:
```
🎉 === COMPREHENSIVE SYSTEM TEST ===

✅ Testing Docker Compose Configuration...
   PASSED
✅ Testing Service Health...
   PASSED
✅ Testing PostgreSQL...
   PASSED (12 songs)
✅ Testing Elasticsearch...
   PASSED (12 documents)
✅ Testing OpenAI Integration...
   PASSED
✅ Testing Search Functionality...
   PASSED

🎵 === SYSTEM VALIDATION COMPLETE ===
```

---

## 🚨 Troubleshooting

### Common Issues and Solutions

#### 1. Services Won't Start
**Symptom**: `docker-compose ps` shows services as "Exited" or "Created"

**Solutions**:
- Check Docker daemon is running
- Verify `.env` file has all required variables
- Check logs: `docker-compose logs [service_name]`
- Restart services: `docker-compose restart`

#### 2. PostgreSQL Connection Fails  
**Symptom**: "Connection refused" or "password authentication failed"

**Solutions**:
- Wait for PostgreSQL to fully initialize (can take 30-60 seconds)
- Verify credentials in `.env` file
- Check PostgreSQL logs: `docker logs postgres-age`

#### 3. No Documents in Elasticsearch
**Symptom**: `curl` queries return 0 documents

**Solutions**:
- Check Logstash logs: `docker logs logstash-postgres`
- Verify PostgreSQL has data: Test 2, Step 3
- Restart Logstash: `docker-compose restart logstash-postgres`

#### 4. OpenAI API Errors
**Symptom**: "Failed to connect to OpenAI API"

**Solutions**:
- Verify `OPENAI_API_KEY` is valid and has credits
- Check internet connectivity
- Verify API key format starts with "sk-"

#### 5. Search Results Empty
**Symptom**: Search queries return no results

**Solutions**:
- Verify documents exist in Elasticsearch (Test 4)
- Check index names and patterns
- Test with simple queries first: `{"query":{"match_all":{}}}`

### Performance Benchmarks

**Expected Performance**:
- **PostgreSQL Query Response**: < 100ms
- **Elasticsearch Search**: < 500ms
- **OpenAI Embedding Generation**: 1-2 seconds per document
- **Full System Startup**: 2-3 minutes
- **Document Processing Rate**: ~10-20 docs/minute

### Monitoring Commands

**Real-time Monitoring**:
```bash
# Monitor all services
docker-compose logs --follow

# Monitor specific service
docker logs logstash-postgres --follow

# Monitor Elasticsearch health
watch 'curl -s -k -u "elastic:password" "https://localhost:9200/_cluster/health"'

# Monitor document count
watch 'curl -s -k -u "elastic:password" "https://localhost:9200/reconciliation-*/_count"'
```

---

## 📊 Test Report Template

Use this template to document your test results:

```
# System Test Report

**Date**: [DATE]
**Tester**: [NAME]
**Environment**: [DEVELOPMENT/STAGING/PRODUCTION]
**System Version**: [GIT_COMMIT/TAG]

## Test Results

| Test Category | Status | Notes |
|---------------|--------|-------|
| Docker Compose | ✅/❌ |       |
| PostgreSQL | ✅/❌ |       |
| Logstash Pipeline | ✅/❌ |       |
| Elasticsearch | ✅/❌ |       |
| OpenAI Integration | ✅/❌ |       |
| Vector Search | ✅/❌ |       |
| File Organization | ✅/❌ |       |

## Performance Metrics

- PostgreSQL Response Time: ___ms
- Elasticsearch Search Time: ___ms
- Document Count: ___
- Services Running: ___/7

## Issues Found

[List any issues discovered during testing]

## Recommendations

[Any suggestions for improvements or fixes]

## Sign-off

**Overall System Status**: [PASS/FAIL/NEEDS ATTENTION]
**Ready for Production**: [YES/NO/WITH CAVEATS]
```

---

**Built with ♪ for the music industry** 🎵
