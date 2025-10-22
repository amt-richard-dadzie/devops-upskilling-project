#!/bin/bash

# Script: list-resources.sh
# Purpose: List all S3 buckets with their regions
# Author: DevOps Upskilling Lab 1.1

# Color codes for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "======================================"
echo "=== S3 Buckets Inventory ==="
echo "======================================"
echo ""

# Get all buckets
BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text)

if [ -z "$BUCKETS" ]; then
    echo "No S3 buckets found in your account."
    exit 0
fi

# Counter for buckets
BUCKET_COUNT=0

# Iterate through each bucket and get its region
for bucket in $BUCKETS; do
    # Get bucket location
    LOCATION=$(aws s3api get-bucket-location --bucket "$bucket" --output text 2>/dev/null)
    
    # Handle the special case where us-east-1 returns "None"
    if [ "$LOCATION" = "None" ] || [ -z "$LOCATION" ]; then
        REGION="us-east-1"
    else
        REGION="$LOCATION"
    fi
    
    echo -e "${CYAN}Bucket:${NC} $bucket ${GREEN}| Region:${NC} $REGION"
    BUCKET_COUNT=$((BUCKET_COUNT + 1))
done

echo ""
echo "======================================"
echo "Total buckets: $BUCKET_COUNT"
echo "======================================"
