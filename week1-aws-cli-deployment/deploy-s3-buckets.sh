#!/bin/bash

# Script: deploy-s3-buckets.sh
# Purpose: Deploy S3 buckets to multiple AWS regions with versioning enabled
# Usage: ./deploy-s3-buckets.sh [--cleanup|--verify]

# Exit on error, but allow incrementing counters
set -e

# Configuration
REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")
BUCKET_PREFIX="amalitech-devops"
TIMESTAMP=$(date +%Y%m%d-%H%M%S) 

# Global arrays to track created buckets
CREATED_BUCKETS=()
DEPLOYMENT_SUCCESS_COUNT=0
DEPLOYMENT_FAILED_COUNT=0

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to create S3 bucket only
create_s3_bucket() {
    local region=$1
    local bucket_name=$2
    
    # Handle us-east-1 special case (no LocationConstraint needed)
    if [ "$region" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$bucket_name" \
            --region "$region"
    else
        # For all other regions, specify LocationConstraint
        aws s3api create-bucket \
            --bucket "$bucket_name" \
            --region "$region" \
            --create-bucket-configuration LocationConstraint="$region"
    fi
}

# Function to enable versioning on bucket
enable_bucket_versioning() {
    local bucket_name=$1
    local region=$2
    
    echo "  Enabling versioning..."
    if aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled \
        --region "$region"; then
        echo -e "${GREEN}  ✓ Versioning enabled${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to enable versioning${NC}"
        return 1
    fi
}

# Function to add tags to bucket
tag_bucket() {
    local bucket_name=$1
    
    echo "  Adding tags..."
    if aws s3api put-bucket-tagging \
        --bucket "$bucket_name" \
        --tagging "TagSet=[{Key=Project,Value=DevOps-Upskilling},{Key=Environment,Value=Lab},{Key=Lab,Value=1.1},{Key=Owner,Value=Student},{Key=ManagedBy,Value=AWS-CLI}]" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Tags applied${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to apply tags${NC}"
        return 1
    fi
}

# Function to create S3 bucket
create_and_configure_bucket() {
    local region=$1
    local bucket_name="${BUCKET_PREFIX}-${region}-${TIMESTAMP}"
    
    echo -e "${YELLOW}Creating bucket in ${region}...${NC}"
    
    if create_s3_bucket "$region" "$bucket_name"; then
        echo -e "${GREEN}✓ Bucket $bucket_name created successfully${NC}"
        CREATED_BUCKETS+=("$bucket_name")
        
        # Enable versioning on the bucket
        enable_bucket_versioning "$bucket_name" "$region"
        
        # Add tags to the bucket
        tag_bucket "$bucket_name"
    else
        echo -e "${RED}✗ Failed to create bucket $bucket_name${NC}"
        return 1
    fi
    
    echo ""
    return 0
}

# Function to get bucket details
get_bucket_details() {
    local bucket=$1
    local location versioning creation_date
    
    # Get bucket location
    location=$(aws s3api get-bucket-location --bucket "$bucket" --output text 2>/dev/null)
    if [ "$location" = "None" ] || [ -z "$location" ]; then
        location="us-east-1"
    fi
    
    # Get versioning status
    versioning=$(aws s3api get-bucket-versioning --bucket "$bucket" --query 'Status' --output text 2>/dev/null)
    if [ -z "$versioning" ]; then
        versioning="Disabled"
    fi
    
    # Get creation date
    creation_date=$(aws s3api list-buckets --query "Buckets[?Name=='$bucket'].CreationDate" --output text 2>/dev/null)
    
    echo "$bucket|$location|$versioning|$creation_date"
}

# Function to find buckets matching prefix
find_matching_buckets() {
    local all_buckets bucket_list=()
    
    # Get list of all buckets
    all_buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null)
    
    if [ -z "$all_buckets" ]; then
        return 1
    fi
    
    # Filter buckets matching our prefix
    for bucket in $all_buckets; do
        if [[ $bucket == ${BUCKET_PREFIX}* ]]; then
            bucket_list+=("$bucket")
        fi
    done
    
    # Return bucket count and list
    if [ ${#bucket_list[@]} -eq 0 ]; then
        return 1
    fi
    
    printf '%s\n' "${bucket_list[@]}"
    return 0
}

# Function to display bucket summary table
display_bucket_table() {
    local bucket_details=("$@")
    
    if [ ${#bucket_details[@]} -eq 0 ]; then
        return 0
    fi
    
    echo -e "${BLUE}📋 Bucket Details:${NC}"
    echo ""
    printf "%-50s %-15s %-12s %-20s\n" "BUCKET NAME" "REGION" "VERSIONING" "CREATED"
    printf "%-50s %-15s %-12s %-20s\n" "$(printf '%.0s-' {1..50})" "$(printf '%.0s-' {1..15})" "$(printf '%.0s-' {1..12})" "$(printf '%.0s-' {1..20})"
    
    for detail in "${bucket_details[@]}"; do
        IFS='|' read -r bucket_name region versioning created <<< "$detail"
        printf "%-50s %-15s %-12s %-20s\n" "$bucket_name" "$region" "$versioning" "$created"
    done
    echo ""
}

# Function to verify individual bucket exists
verify_bucket_exists() {
    local bucket=$1
    aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1
}

# function to verify buckets 
verify_buckets() {
    local mode="${1:-existing}"
    local bucket_list=()
    
    # Set up verification context based on mode
    if [ "$mode" = "deployment" ]; then
        if [ ${#CREATED_BUCKETS[@]} -eq 0 ]; then
            echo -e "${YELLOW}No buckets to verify (none were created successfully)${NC}"
            return 1
        fi
        
        bucket_list=("${CREATED_BUCKETS[@]}")
        echo -e "${BLUE}Verifying ${#bucket_list[@]} created bucket(s)...${NC}"
    else
        echo "======================================"
        echo "🔍 Existing Buckets Verification"
        echo "======================================"
        echo ""
        
        # Find matching buckets using helper function
        if find_matching_buckets > /tmp/bucket_list; then
            readarray -t bucket_list < /tmp/bucket_list
            rm -f /tmp/bucket_list
        else
            echo -e "${YELLOW}No S3 buckets found in your account.${NC}"
            return 0
        fi
        
        if [ ${#bucket_list[@]} -eq 0 ]; then
            echo -e "${YELLOW}No buckets found matching prefix '${BUCKET_PREFIX}'${NC}"
            return 0
        fi
        
        echo -e "${BLUE}Found ${#bucket_list[@]} bucket(s) matching prefix${NC}"
    fi
    
    echo ""
    
    # Process bucket verification
    local verification_success=0
    local verification_failed=0
    local bucket_details=()
    
    # Verify each bucket (silent processing)
    for bucket in "${bucket_list[@]}"; do
        echo -e "${CYAN}Checking bucket: ${bucket}${NC}..."
        
        if verify_bucket_exists "$bucket"; then
            bucket_details+=($(get_bucket_details "$bucket"))
            verification_success=$((verification_success + 1))
        else
            verification_failed=$((verification_failed + 1))
        fi
    done
    
    # Display results using helper function
    display_bucket_table "${bucket_details[@]}"
    
    if [ $verification_failed -gt 0 ]; then
        echo -e "${RED}Failed verification: $verification_failed${NC}"
        echo ""
    fi
    
    # Overall verification result
    if [ $verification_failed -eq 0 ]; then
        if [ "$mode" = "deployment" ]; then
            echo -e "${GREEN}📍 Total buckets created: ${#bucket_list[@]} across ${#REGIONS[@]} regions${NC}"
        else
            echo -e "${GREEN}📍 Total buckets: ${#bucket_list[@]}${NC}"
        fi
        return 0
    else
        echo -e "${RED}⚠️  Some buckets failed verification${NC}"
        return 1
    fi
}

# Function to get bucket region
get_bucket_region() {
    local bucket=$1
    local location
    
    location=$(aws s3api get-bucket-location --bucket "$bucket" --output text 2>/dev/null)
    if [ "$location" = "None" ] || [ -z "$location" ]; then
        echo "us-east-1"
    else
        echo "$location"
    fi
}

# Function to empty and delete a bucket
delete_single_bucket() {
    local bucket=$1
    local region=$2
    
    echo -e "${YELLOW}Deleting bucket: ${bucket}${NC}"
    
    # Empty the bucket (delete all current objects)
    echo "  Emptying bucket contents..."
    aws s3 rm "s3://${bucket}" --recursive --region "$region" &>/dev/null || true
    
    # Delete the bucket
    echo "  Deleting bucket..."
    if aws s3api delete-bucket --bucket "$bucket" --region "$region" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Bucket ${bucket} deleted successfully${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to delete bucket ${bucket}${NC}"
        return 1
    fi
}

# Function to display buckets for confirmation
display_buckets_for_deletion() {
    local buckets=("$@")
    
    echo -e "${YELLOW}Found ${#buckets[@]} bucket(s) to delete:${NC}"
    echo ""
    for bucket in "${buckets[@]}"; do
        local region=$(get_bucket_region "$bucket")
        echo -e "  ${RED}✗${NC} $bucket ${CYAN}(${region})${NC}"
    done
    echo ""
}

# Function to get user confirmation
get_deletion_confirmation() {
    local confirm
    read -p "Are you sure you want to delete these buckets? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${GREEN}Cleanup cancelled.${NC}"
        return 1
    fi
    return 0
}

# Function to delete all buckets matching prefix
cleanup_buckets() {
    echo "======================================"
    echo "S3 Bucket Cleanup"
    echo "======================================"
    echo ""
    
    echo -e "${CYAN}Searching for buckets with prefix: ${BUCKET_PREFIX}${NC}"
    echo ""
    
    # Find matching buckets using helper function
    local matching_buckets=()
    if find_matching_buckets > /tmp/bucket_list; then
        readarray -t matching_buckets < /tmp/bucket_list
        rm -f /tmp/bucket_list
    else
        echo -e "${YELLOW}No S3 buckets found in your account.${NC}"
        exit 0
    fi
    
    # Check if any matching buckets found
    if [ ${#matching_buckets[@]} -eq 0 ]; then
        echo -e "${YELLOW}No buckets found matching prefix '${BUCKET_PREFIX}'${NC}"
        exit 0
    fi
    
    # Display buckets to be deleted
    display_buckets_for_deletion "${matching_buckets[@]}"
    
    # Confirmation prompt
    if ! get_deletion_confirmation; then
        exit 0
    fi
    
    echo ""
    echo "======================================"
    echo "Starting deletion process..."
    echo "======================================"
    echo ""
    
    # Delete all matching buckets
    local delete_success=0
    local delete_failed=0
    
    for bucket in "${matching_buckets[@]}"; do
        local region=$(get_bucket_region "$bucket")
        
        if delete_single_bucket "$bucket" "$region"; then
            delete_success=$((delete_success + 1))
        else
            delete_failed=$((delete_failed + 1))
        fi
        echo ""
    done
    
    # Summary
    echo -e "${GREEN}Successfully deleted: $delete_success${NC}"
    if [ $delete_failed -gt 0 ]; then
        echo -e "${RED}Failed: $delete_failed${NC}"
    fi
    echo ""
    
    if [ $delete_failed -eq 0 ]; then
        echo -e "${GREEN}✓ All buckets cleaned up successfully!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some buckets failed to delete${NC}"
        exit 1
    fi
}

# Function to show usage information
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  (no options)    Deploy S3 buckets to multiple regions"
    echo "  --cleanup, -c   Delete all buckets matching the prefix"
    echo "  --verify, -v    Verify existing buckets without deploying"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Deploy buckets"
    echo "  $0 --cleanup    # Delete all deployed buckets"
    echo "  $0 --verify     # Verify existing buckets"
    echo ""
}

# Main function to control script flow
main() {
    case "${1:-}" in
        "--cleanup"|"-c")
            cleanup_buckets
            ;;
        "--verify"|"-v")
            verify_buckets "existing"
            ;;
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        "")
            # Deploy buckets to all regions
            echo "======================================"
            echo "S3 Multi-Region Bucket Deployment"
            echo "======================================"
            echo "Timestamp: $TIMESTAMP"
            echo ""
            
            # Reset counters and arrays
            DEPLOYMENT_SUCCESS_COUNT=0
            DEPLOYMENT_FAILED_COUNT=0
            CREATED_BUCKETS=()
            
            # Create buckets in each region
            for region in "${REGIONS[@]}"; do
                if create_and_configure_bucket "$region"; then
                    DEPLOYMENT_SUCCESS_COUNT=$((DEPLOYMENT_SUCCESS_COUNT + 1))
                else
                    DEPLOYMENT_FAILED_COUNT=$((DEPLOYMENT_FAILED_COUNT + 1))
                fi
            done
            
            # Run verification if any buckets were created
            if [ $DEPLOYMENT_SUCCESS_COUNT -gt 0 ]; then
                verify_buckets "deployment"
                local verification_result=$?
                
                if [ $verification_result -eq 0 ] && [ $DEPLOYMENT_FAILED_COUNT -eq 0 ]; then
                    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
                    exit 0
                else
                    echo -e "${RED}⚠️ Deployment completed with issues${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}✗ No buckets were deployed successfully${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Script execution starts here
main "$@"