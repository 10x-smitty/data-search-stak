# Elastic Stack Docker - Quick Start Guide

This guide will help you quickly set up and customize the Elastic Stack for your own project.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of available RAM
- Ports 9200 (Elasticsearch) and 5601 (Kibana) available

## Quick Start Commands

### 1. Clone and Setup

```bash
# Clone the repository (or fork it first)
git clone https://github.com/elkninja/elastic-stack-docker-part-one.git
cd elastic-stack-docker-part-one

# Optional: Create a backup of the original .env file
cp .env .env.backup
```

### 2. Customize Environment (Optional)

Edit the `.env` file to customize for your project:

```bash
# Edit environment variables
vim .env
```

Key variables to consider updating:
- `COMPOSE_PROJECT_NAME=your-project-name`
- `CLUSTER_NAME=your-cluster-name` 
- `ELASTIC_PASSWORD=your_secure_password`
- `KIBANA_PASSWORD=your_secure_kibana_password`

### 3. Start the Stack

```bash
# Start all services in detached mode
docker-compose up -d

# View logs (optional)
docker-compose logs -f
```

### 4. Verify Installation

```bash
# Check service status
docker-compose ps

# Test Elasticsearch connection
curl -u elastic:password -k https://localhost:9200

# Test Kibana (wait a few minutes for startup)
curl -I http://localhost:5601
```

### 5. Access the Services

```bash
# Open Kibana in your browser
open http://localhost:5601
# Login: elastic / password (or your custom password)
```

**Service URLs:**
- **Kibana**: http://localhost:5601
- **Elasticsearch**: https://localhost:9200 
- **PostgreSQL (Apache AGE)**: localhost:5432
- **Credentials**: 
  - Elastic Stack: `elastic` / `password` (default)
  - PostgreSQL: `postgres` / `postgres` (default)

## Common Operations

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f elasticsearch
docker-compose logs -f kibana
```

### Stop Services
```bash
# Stop all services
docker-compose stop

# Stop and remove containers (keeps data)
docker-compose down

# Remove everything including volumes (⚠️ DELETES DATA)
docker-compose down -v
```

### Restart Services
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart elasticsearch
```

## PostgreSQL with Apache AGE

The stack includes PostgreSQL with the Apache AGE extension for graph database capabilities.

### Connecting to PostgreSQL
```bash
# Connect using psql (if installed locally)
psql -h localhost -p 5432 -U postgres -d agedb

# Or connect using Docker
docker-compose exec postgres psql -U postgres -d agedb
```

### Using Apache AGE
```sql
-- Set search path for AGE functions
SET search_path = ag_catalog, "$user", public;

-- Create a new graph
SELECT create_graph('my_graph');

-- Create vertices
SELECT * FROM cypher('my_graph', $$
    CREATE (:Person {name: 'Alice', age: 30})
$$) AS (v agtype);

-- Query the graph
SELECT * FROM cypher('my_graph', $$
    MATCH (p:Person) 
    RETURN p.name, p.age
$$) AS (name agtype, age agtype);
```

### Configuration Files
- **Initialization**: `postgres-init/01-init-age.sql` - Runs on first startup
- **Environment**: PostgreSQL settings in `.env` file

## Local Data Structure

All persistent data is stored locally in the `data/` directory for easy access and backup:

```
data/
├── certs/          # SSL certificates
├── elasticsearch/  # Elasticsearch indices and data
├── kibana/         # Kibana configuration and objects
├── postgres/       # PostgreSQL database files
├── metricbeat/     # Metricbeat registry data
├── filebeat/       # Filebeat registry data
└── logstash/       # Logstash persistent queue data
```

**Benefits:**
- ✅ **Easy Backup**: Simply copy the `data/` directory
- ✅ **Portable**: Move the entire setup by copying the project folder
- ✅ **Accessible**: Inspect database files directly on your filesystem
- ✅ **Version Control**: Data is excluded via `.gitignore`

## Next Steps

1. **Remove Sample Data**: Delete `filebeat_ingest_data/` and `logstash_ingest_data/` directories
2. **Configure Data Sources**: Update `filebeat.yml` and `logstash.conf` for your data
3. **Explore Kibana**: Create dashboards and visualizations for your data
4. **Set Up Index Templates**: Define mappings for your data types
5. **Configure Monitoring**: Set up alerts and monitoring rules
6. **Explore Graph Database**: Use Apache AGE for graph data modeling and queries
7. **Set Up Data Reconciliation**: Use vector search for fuzzy matching and duplicate detection

## CSV Data Reconciliation & Vector Search

The stack includes powerful data reconciliation capabilities using vector search - perfect for "fuzzy matching on steroids":

### Features
- **Row-by-Row Processing**: Each CSV row becomes an individual searchable document
- **Cross-Source Matching**: Find similar records across different data sources (e.g., different PROs)
- **Fuzzy Name Matching**: Handles variations like "John Smith" vs "Smith, John" vs "J. Smith"
- **Missing Data Tolerance**: Can match records even with incomplete information
- **ID Reconciliation**: Extracts and matches IPI numbers, codes, and identifiers
- **Normalized Content**: Multiple searchable content formats for better matching

### Configuration Options
1. **Generic CSV Processing** (`logstash-csv-vector.conf`): Works with any CSV structure
2. **Reconciliation-Optimized** (`logstash-csv-reconciliation.conf`): Enhanced for data matching

### Use Cases
- **Music Rights Data**: Match songs across ASCAP, BMI, SESAC databases
- **Customer Records**: Find duplicate customers with different spellings/formats
- **Product Catalogs**: Match products across different vendor systems
- **Financial Records**: Reconcile transactions across multiple sources

### Getting Started with Reconciliation

1. **Place CSV files** in `logstash_ingest_data/` directory
2. **Apply index template**:
   ```bash
   curl -X PUT "https://localhost:9200/_index_template/reconciliation" \
     -H "Content-Type: application/json" \
     -u elastic:password -k \
     -d @elasticsearch-templates/reconciliation-template.json
   ```
3. **Update Logstash configuration** to use reconciliation pipeline:
   ```bash
   # Edit docker-compose.yml to use logstash-csv-reconciliation.conf
   docker-compose restart logstash01
   ```
4. **Use sample queries** from `reconciliation-queries.json` to find matches

### Sample Queries
See `reconciliation-queries.json` for example queries including:
- Vector similarity search for finding duplicates
- Hybrid traditional + vector search  
- Cross-source reconciliation
- Exact ID matching

## Troubleshooting

### Services Won't Start
```bash
# Check system resources
docker system df
docker system prune  # Free up space

# Check memory settings
# Increase Docker memory limit to 4GB+ in Docker Desktop
```

### Certificate Issues
```bash
# Restart setup service to regenerate certificates
docker-compose restart setup
docker-compose up -d
```

### Port Conflicts
```bash
# Check what's using the ports
lsof -i :9200
lsof -i :5601

# Update ports in .env file if needed
ES_PORT=9201
KIBANA_PORT=5602
```

### Reset Everything
```bash
# Stop and remove everything (including data)
docker-compose down

# Remove persistent data (⚠️ THIS DELETES ALL DATA)
rm -rf data/

# Recreate data directories
mkdir -p data/{elasticsearch,kibana,postgres,metricbeat,filebeat,logstash,certs}

# Remove any orphaned containers
docker container prune -f

# Start fresh
docker-compose up -d
```

## Security Notes

- **Default passwords** are set to `password` - change these for any non-development use
- **SSL certificates** are auto-generated for secure communication
- **X-Pack security** is enabled with basic authentication
- The setup generates a **32-character encryption key** for Kibana

## Resource Requirements

**Minimum:**
- 4GB RAM
- 2 CPU cores
- 10GB disk space

**Recommended:**
- 8GB+ RAM
- 4+ CPU cores  
- 50GB+ disk space (for data growth)

## Support

- [Official Elastic Documentation](https://www.elastic.co/guide/)
- [Community Forums](https://discuss.elastic.co/)
- [Community Slack](https://ela.st/slack)
- [Project Issues](https://github.com/elkninja/elastic-stack-docker-part-one/issues)
