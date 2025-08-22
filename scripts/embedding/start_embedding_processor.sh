#!/bin/bash

# Start OpenAI Embedding Processor in background
# This script loads environment variables and runs the processor continuously

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables from project root
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
    echo "Loaded environment variables from .env"
else
    echo "Warning: .env file not found at $PROJECT_ROOT/.env"
fi

# Check if processor is already running
if pgrep -f "openai_embedding_processor.sh" > /dev/null; then
    echo "OpenAI embedding processor is already running"
    pgrep -f "openai_embedding_processor.sh"
    exit 0
fi

# Start the processor in background
echo "Starting OpenAI embedding processor in continuous mode..."
nohup ./openai_embedding_processor.sh --continuous 30 > ../../embedding_processor.log 2>&1 &

PROCESSOR_PID=$!
echo "OpenAI embedding processor started with PID: $PROCESSOR_PID"
echo "Logs are being written to: embedding_processor.log"
echo ""
echo "To stop the processor, run:"
echo "  kill $PROCESSOR_PID"
echo ""
echo "To check logs:"
echo "  tail -f embedding_processor.log"
