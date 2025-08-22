#!/usr/bin/env python3
"""
OpenAI Embedding Processor for Elasticsearch
Monitors Elasticsearch for documents needing embeddings and processes them using OpenAI API
"""

import os
import sys
import time
import json
import requests
import logging
from typing import List, Dict, Any, Optional
from elasticsearch import Elasticsearch
from elasticsearch.exceptions import NotFoundError, RequestError
import openai

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OpenAIEmbeddingProcessor:
    def __init__(self):
        # Load configuration from environment
        self.openai_api_key = os.getenv('OPENAI_API_KEY')
        self.openai_model = os.getenv('OPENAI_MODEL', 'text-embedding-3-small')
        self.openai_dims = int(os.getenv('OPENAI_DIMS', '1536'))
        
        self.elastic_host = os.getenv('ELASTIC_HOST', 'https://localhost:9200')
        self.elastic_user = os.getenv('ELASTIC_USER', 'elastic')
        self.elastic_password = os.getenv('ELASTIC_PASSWORD', 'password')
        
        # Initialize OpenAI client
        openai.api_key = self.openai_api_key
        
        # Initialize Elasticsearch client
        self.es = Elasticsearch(
            [self.elastic_host],
            basic_auth=(self.elastic_user, self.elastic_password),
            verify_certs=False,
            ssl_show_warn=False
        )
        
        # Test connections
        self._test_connections()
    
    def _test_connections(self):
        """Test connections to OpenAI and Elasticsearch"""
        try:
            # Test Elasticsearch connection
            info = self.es.info()
            logger.info(f"Connected to Elasticsearch: {info['version']['number']}")
        except Exception as e:
            logger.error(f"Failed to connect to Elasticsearch: {e}")
            sys.exit(1)
        
        try:
            # Test OpenAI connection by making a simple embedding request
            response = openai.Embedding.create(
                model=self.openai_model,
                input="test connection"
            )
            logger.info(f"Connected to OpenAI API - Model: {self.openai_model}")
        except Exception as e:
            logger.error(f"Failed to connect to OpenAI API: {e}")
            sys.exit(1)
    
    def get_documents_needing_embeddings(self, index_pattern: str = "reconciliation-*") -> List[Dict[str, Any]]:
        """Find documents that need embeddings"""
        try:
            query = {
                "query": {
                    "bool": {
                        "must": [
                            {"term": {"needs_embedding": True}},
                            {"exists": {"field": "searchable_content"}}
                        ],
                        "must_not": [
                            {"exists": {"field": "text_embedding"}}
                        ]
                    }
                },
                "size": 10  # Process in batches
            }
            
            response = self.es.search(index=index_pattern, body=query)
            documents = []
            
            for hit in response['hits']['hits']:
                documents.append({
                    'index': hit['_index'],
                    'id': hit['_id'],
                    'source': hit['_source']
                })
            
            return documents
            
        except Exception as e:
            logger.error(f"Error searching for documents needing embeddings: {e}")
            return []
    
    def generate_embedding(self, text: str) -> Optional[List[float]]:
        """Generate embedding for text using OpenAI API"""
        try:
            response = openai.Embedding.create(
                model=self.openai_model,
                input=text
            )
            
            embedding = response['data'][0]['embedding']
            
            # Verify dimensions
            if len(embedding) != self.openai_dims:
                logger.warning(f"Unexpected embedding dimensions: {len(embedding)} vs {self.openai_dims}")
            
            return embedding
            
        except Exception as e:
            logger.error(f"Error generating embedding for text: {e}")
            return None
    
    def update_document_with_embedding(self, doc_index: str, doc_id: str, embedding: List[float]):
        """Update document with generated embedding"""
        try:
            update_body = {
                "doc": {
                    "text_embedding": embedding,
                    "needs_embedding": False,
                    "embedding_generated_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "embedding_model_used": self.openai_model,
                    "embedding_status": "completed"
                }
            }
            
            self.es.update(
                index=doc_index,
                id=doc_id,
                body=update_body
            )
            
            logger.info(f"Updated document {doc_id} with embedding")
            
        except Exception as e:
            logger.error(f"Error updating document {doc_id} with embedding: {e}")
            # Mark document as failed
            try:
                self.es.update(
                    index=doc_index,
                    id=doc_id,
                    body={
                        "doc": {
                            "needs_embedding": False,
                            "embedding_status": "failed",
                            "embedding_error": str(e),
                            "embedding_failed_at": time.strftime("%Y-%m-%dT%H:%M:%S.000Z")
                        }
                    }
                )
            except:
                pass
    
    def process_pending_embeddings(self):
        """Main processing loop"""
        logger.info("Starting embedding processing...")
        
        documents = self.get_documents_needing_embeddings()
        
        if not documents:
            logger.info("No documents need embeddings")
            return 0
        
        logger.info(f"Processing {len(documents)} documents for embeddings")
        
        processed = 0
        for doc in documents:
            try:
                searchable_content = doc['source'].get('searchable_content', '')
                
                if not searchable_content:
                    logger.warning(f"Document {doc['id']} has no searchable_content")
                    continue
                
                logger.info(f"Generating embedding for document: {doc['id']}")
                logger.debug(f"Content: {searchable_content[:100]}...")
                
                # Generate embedding
                embedding = self.generate_embedding(searchable_content)
                
                if embedding:
                    # Update document
                    self.update_document_with_embedding(
                        doc['index'], 
                        doc['id'], 
                        embedding
                    )
                    processed += 1
                else:
                    logger.error(f"Failed to generate embedding for document {doc['id']}")
                    
                # Rate limiting - OpenAI has rate limits
                time.sleep(0.5)
                
            except Exception as e:
                logger.error(f"Error processing document {doc['id']}: {e}")
        
        logger.info(f"Processed {processed} documents")
        return processed
    
    def run_continuous(self, interval_seconds: int = 30):
        """Run continuous processing loop"""
        logger.info(f"Starting continuous embedding processor (interval: {interval_seconds}s)")
        
        while True:
            try:
                self.process_pending_embeddings()
                time.sleep(interval_seconds)
            except KeyboardInterrupt:
                logger.info("Received interrupt signal, stopping...")
                break
            except Exception as e:
                logger.error(f"Error in continuous processing: {e}")
                time.sleep(interval_seconds)

def main():
    """Main entry point"""
    processor = OpenAIEmbeddingProcessor()
    
    # Check command line arguments
    if len(sys.argv) > 1 and sys.argv[1] == "--continuous":
        # Run continuous processing
        interval = int(sys.argv[2]) if len(sys.argv) > 2 else 30
        processor.run_continuous(interval)
    else:
        # Run once
        processed = processor.process_pending_embeddings()
        logger.info(f"Single run completed. Processed {processed} documents.")

if __name__ == "__main__":
    main()
