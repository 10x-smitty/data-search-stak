# Music Rights Reconciliation System

A comprehensive, vector-powered music rights reconciliation system built with the Elastic Stack, PostgreSQL, and OpenAI embeddings. This system enables cross-source data matching, duplicate detection, and rights reconciliation across different PROs (Performing Rights Organizations) and publishers.

## 🎵 Overview

This project provides:
- **Cross-source reconciliation** between ASCAP, BMI, SESAC, and other music rights databases
- **Semantic vector search** using OpenAI embeddings for fuzzy matching
- **Multi-strategy search** combining text, vector, and exact matching
- **Automated data ingestion** from PostgreSQL and CSV sources
- **Real-time processing** of music rights metadata

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │      CSV Files   │    │   External APIs │
│  Music Rights   │───▶│   (PRO Exports)  │───▶│   (Future)      │
│   Database      │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                       │
         ▼                        ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Logstash                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  PostgreSQL     │  │   CSV Vector    │  │   Future        │  │
│  │   Pipeline      │  │   Pipeline      │  │   Pipelines     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Elasticsearch                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Reconciliation  │  │  Vector Index   │  │   Text Search   │  │
│  │   Indices       │  │  (1536 dims)    │  │    Indices      │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 OpenAI Embedding Service                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Shell Script  │  │  Python Option  │  │    Batch       │  │
│  │   Processor     │  │   (Available)   │  │   Processing    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Kibana                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Dashboards    │  │   Search UI     │  │   Analytics     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
music-rights-reconciliation/
├── logstash/                       # Logstash service
│   ├── logstash-csv-vector.conf          # CSV data ingestion pipeline
│   ├── logstash-postgres-simple.conf     # PostgreSQL data ingestion pipeline
│   ├── ingest-data/               # CSV files for ingestion
│   │   ├── ASCAP_Catalog_Export.csv      # ASCAP sample data
│   │   ├── BMI_Catalog_Export.csv        # BMI sample data
│   │   └── SESAC_Catalog_Export.csv      # SESAC sample data
│   └── drivers/                   # JDBC drivers
│       └── postgresql-42.7.1.jar         # PostgreSQL JDBC driver
│
├── filebeat/                       # Filebeat service
│   ├── filebeat.yml               # Filebeat configuration
│   └── ingest-data/               # Log files for ingestion
│       └── Air_Quality.log              # Sample log data
│
├── metricbeat/                     # Metricbeat service
│   └── metricbeat.yml             # Metrics collection configuration
│
├── elasticsearch/                  # Elasticsearch service
│   └── templates/                # Template definitions
│       ├── index/                    # Elasticsearch index templates
│       └── pipeline/                 # Ingest pipeline templates
│
├── scripts/                        # Utility scripts
│   ├── embedding/                 # Vector embedding processing
│   │   ├── openai_embedding_processor.sh   # Shell-based OpenAI processor
│   │   ├── start_embedding_processor.sh    # Background service launcher
│   │   ├── openai_embedding_processor.py   # Python alternative processor
│   │   └── requirements.txt               # Python dependencies
│   ├── setup/                     # Setup and installation scripts
│   │   ├── setup-configurable-vector-search.sh
│   │   ├── setup-postgres-templates.sh
│   │   └── setup-vector-search.sh
│   └── testing/                   # Testing and validation scripts
│       ├── test_vector_search.sh          # Vector search tests
│       ├── simple_vector_test.sh         # Basic functionality tests
│       └── vector-search-examples.sh     # Example queries
│
├── docs/                          # Documentation
│   ├── setup/                     # Setup documentation
│   │   └── MUSIC_RIGHTS_SETUP.md         # Detailed setup guide
│   ├── examples/                  # Usage examples
│   │   └── practical-search-examples.md   # Search examples
│   └── queries/                   # Query collections
│       ├── cross-source-reconciliation-queries.json
│       ├── reconciliation-queries.json
│       └── search-strategies-guide.json
│
├── postgres/                      # PostgreSQL service
│   ├── 01-music-rights-schema.sql       # Database schema
│   ├── 02-music-rights-views.sql        # Database views
│   └── 03-music-rights-data.sql         # Sample data
│
├── data/                         # Runtime data (auto-generated)
│   ├── elasticsearch/           # Elasticsearch data
│   ├── kibana/                  # Kibana data
│   ├── logstash/                # CSV Logstash data
│   ├── logstash-postgres/       # PostgreSQL Logstash data
│   ├── postgres/                # PostgreSQL data
│   └── certs/                   # SSL certificates
│
├── docker-compose.yml           # Docker orchestration
├── .env                        # Environment configuration
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- OpenAI API key (for vector embeddings)
- 8GB+ RAM recommended

### 1. Clone and Configure

```bash
git clone <repository-url>
cd music-rights-reconciliation

# Configure environment variables
cp .env.example .env
# Edit .env file with your OpenAI API key and other settings
```

### 2. Start the Stack

```bash
# Start the core Elastic Stack + PostgreSQL
docker-compose up -d

# Start PostgreSQL data ingestion
docker-compose up -d logstash-postgres
```

### 3. Process Vector Embeddings

```bash
# Start OpenAI embedding processor
./scripts/embedding/start_embedding_processor.sh

# Or run once manually:
export $(grep -v '^#' .env | xargs) && ./scripts/embedding/openai_embedding_processor.sh
```

### 4. Test the System

```bash
# Run basic functionality tests
./scripts/testing/simple_vector_test.sh

# Run vector similarity search tests
./scripts/testing/test_vector_search.sh "Beatles song by Lennon McCartney"
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Elastic Stack
ELASTIC_PASSWORD=your-secure-password
KIBANA_PASSWORD=your-kibana-password
STACK_VERSION=8.7.1

# OpenAI Vector Embeddings
VECTOR_EMBEDDING_STRATEGY=openai
OPENAI_API_KEY=sk-your-openai-key
OPENAI_MODEL=text-embedding-3-small
OPENAI_DIMS=1536

# PostgreSQL
POSTGRES_DB=agedb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Memory Limits
ES_MEM_LIMIT=1073741824
KB_MEM_LIMIT=1073741824
LS_MEM_LIMIT=1073741824
```

### Data Sources

#### PostgreSQL Schema
The system includes a complete music rights schema with:
- **Writers**: Artist information with IPI numbers
- **Publishers**: Publishing company details
- **Songs**: Track metadata with ISWC codes
- **Relationships**: Writer-song and publisher-song associations
- **Rights**: Ownership percentages and territories

#### CSV Data Sources
Sample CSV files for major PROs:
- **ASCAP**: American Society of Composers, Authors and Publishers
- **BMI**: Broadcast Music, Inc.
- **SESAC**: Society of European Stage Authors and Composers

## 📊 Search Capabilities

### 1. Vector Similarity Search
```bash
# Semantic search using OpenAI embeddings
./scripts/testing/test_vector_search.sh "pop song by Taylor Swift"
```

### 2. Cross-Source Reconciliation
```json
{
  "query": {
    "bool": {
      "must": [
        {"match": {"title": "Hey Jude"}},
        {"terms": {"data_source": ["postgresql", "ascap", "bmi"]}}
      ]
    }
  }
}
```

### 3. Fuzzy Matching
```json
{
  "query": {
    "fuzzy": {
      "writers": {
        "value": "John Lennon",
        "fuzziness": "AUTO"
      }
    }
  }
}
```

### 4. Exact Identifier Matching
```json
{
  "query": {
    "bool": {
      "should": [
        {"term": {"iswc": "T-070.246.800-1"}},
        {"term": {"writers.ipi": "00014107338"}}
      ]
    }
  }
}
```

## 🔍 Usage Examples

### Find Similar Songs Across PROs
```bash
# Find all versions of "Imagine" across different sources
curl -X GET "localhost:9200/reconciliation-*/_search" -H "Content-Type: application/json" -d '{
  "query": {
    "multi_match": {
      "query": "Imagine John Lennon",
      "fields": ["title^2", "writers", "normalized_content"]
    }
  },
  "aggs": {
    "by_source": {
      "terms": {
        "field": "data_source"
      }
    }
  }
}'
```

### Reconcile Publisher Information
```bash
# Find discrepancies in publisher data
curl -X GET "localhost:9200/reconciliation-*/_search" -H "Content-Type: application/json" -d '{
  "query": {
    "bool": {
      "must": [
        {"match": {"title": "Yesterday"}}
      ]
    }
  },
  "aggs": {
    "publishers": {
      "terms": {
        "field": "publishers.keyword"
      }
    }
  }
}'
```

## 🛠️ Development

### Adding New Data Sources

1. **Create Logstash Configuration**:
   ```bash
   # Create new pipeline config
   cp logstash/logstash-postgres-simple.conf logstash/logstash-new-source.conf
   # Edit configuration for your data source
   ```

2. **Update Docker Compose**:
   ```yaml
   logstash-new-source:
     image: docker.elastic.co/logstash/logstash:${STACK_VERSION}
     volumes:
       - "./logstash/logstash-new-source.conf:/usr/share/logstash/pipeline/logstash.conf:ro"
   ```

3. **Test and Deploy**:
   ```bash
   docker-compose up -d logstash-new-source
   ```

### Custom Vector Processing

```python
# Use the Python embedding processor for custom logic
cd scripts/embedding/
pip install -r requirements.txt
python openai_embedding_processor.py --continuous
```

## 📈 Monitoring

Access monitoring interfaces:
- **Kibana**: http://localhost:5601
- **Elasticsearch**: https://localhost:9200
- **PostgreSQL**: localhost:5432

### Key Metrics
- **Document count**: Total ingested records
- **Embedding status**: Vector processing completion
- **Cross-source matches**: Reconciliation success rate
- **Query performance**: Search response times

## 🔐 Security

- **SSL/TLS**: All Elastic Stack communications encrypted
- **Authentication**: Basic auth for all services
- **API Keys**: OpenAI key secured in environment variables
- **Network**: Docker internal networking only

## 📚 Documentation

- [Detailed Setup Guide](docs/setup/MUSIC_RIGHTS_SETUP.md)
- [Search Examples](docs/examples/practical-search-examples.md)
- [Query Collections](docs/queries/)
- [API Documentation](https://elastic.co/guide/en/elasticsearch/reference/current/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

[License details]

## 🆘 Support

For issues and questions:
1. Check the [Setup Guide](docs/setup/MUSIC_RIGHTS_SETUP.md)
2. Review [Example Queries](docs/queries/)
3. Run diagnostic tests: `./scripts/testing/simple_vector_test.sh`
4. Check logs: `tail -f embedding_processor.log`

---

**Built with ♪ for the music industry**
