#!/bin/bash

# AWS Security Audit Script
# This script performs automated security checks across AWS services

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

echo "======================================"
echo "AWS Security Audit"
echo "======================================"
echo "Started: $(date)"
echo ""

# Function to print results
print_result() {
    if [ "$1" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $2"
        ((PASS_COUNT++))
    elif [ "$1" == "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $2"
        ((WARN_COUNT++))
    else
        echo -e "${RED}✗${NC} $2"
        ((FAIL_COUNT++))
    fi
}

# ==========================================
# 1. S3 BUCKET SECURITY CHECKS
# ==========================================
echo "======================================"
echo "1. S3 Bucket Security"


# Get all S3 buckets
BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null)

if [ -z "$BUCKETS" ]; then
    print_result "WARN" "No S3 buckets found or unable to list buckets"
else
    BUCKET_COUNT=$(echo "$BUCKETS" | wc -w)
    echo "Found $BUCKET_COUNT bucket(s) to audit"
    echo ""
    
    for BUCKET in $BUCKETS; do
        echo "Checking bucket: $BUCKET"
        
        # Check public access block
        PUBLIC_BLOCK=$(aws s3api get-public-access-block --bucket "$BUCKET" 2>&1)
        if echo "$PUBLIC_BLOCK" | grep -q "NoSuchPublicAccessBlockConfiguration"; then
            print_result "FAIL" "  Public access block not configured for $BUCKET"
        elif echo "$PUBLIC_BLOCK" | grep -q "BlockPublicAcls.*true" && \
             echo "$PUBLIC_BLOCK" | grep -q "BlockPublicPolicy.*true"; then
            print_result "PASS" "  Public access properly blocked for $BUCKET"
        else
            print_result "WARN" "  Public access block partially configured for $BUCKET"
        fi
        
        # Check encryption
        ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET" 2>&1)
        if echo "$ENCRYPTION" | grep -q "ServerSideEncryptionConfigurationNotFoundError"; then
            print_result "FAIL" "  Encryption not enabled for $BUCKET"
        else
            print_result "PASS" "  Encryption enabled for $BUCKET"
        fi
        
        echo ""
    done
fi

# ==========================================
# 2. IAM SECURITY CHECKS
# ==========================================
echo "======================================"
echo "2. IAM Security"


# Check root account MFA
ACCOUNT_SUMMARY=$(aws iam get-account-summary 2>/dev/null)
if echo "$ACCOUNT_SUMMARY" | grep -q '"AccountMFAEnabled": 1'; then
    print_result "PASS" "Root account MFA is enabled"
else
    print_result "FAIL" "Root account MFA is NOT enabled"
fi

# Check password policy
PASSWORD_POLICY=$(aws iam get-account-password-policy 2>&1)
if echo "$PASSWORD_POLICY" | grep -q "NoSuchEntity"; then
    print_result "FAIL" "No password policy configured"
else
    print_result "PASS" "Password policy is configured"
    
    # Check specific password policy requirements
    if echo "$PASSWORD_POLICY" | grep -q '"MinimumPasswordLength": [0-9]\+' && \
       [ $(echo "$PASSWORD_POLICY" | grep -o '"MinimumPasswordLength": [0-9]\+' | grep -o '[0-9]\+') -ge 14 ]; then
        print_result "PASS" "  Password minimum length >= 14 characters"
    else
        print_result "WARN" "  Password minimum length < 14 characters"
    fi
    
    if echo "$PASSWORD_POLICY" | grep -q '"RequireSymbols": true'; then
        print_result "PASS" "  Password requires symbols"
    else
        print_result "WARN" "  Password does not require symbols"
    fi
fi

# Generate credential report
echo ""
echo "Generating IAM credential report..."
aws iam generate-credential-report >/dev/null 2>&1
sleep 2
CRED_REPORT=$(aws iam get-credential-report --query 'Content' --output text 2>/dev/null | base64 -d)

if [ -n "$CRED_REPORT" ]; then
    print_result "PASS" "Credential report generated successfully"
    
    # Check for users without MFA
    USERS_NO_MFA=$(echo "$CRED_REPORT" | awk -F',' 'NR>1 && $4=="true" && $8=="false" {print $1}' | wc -l)
    if [ "$USERS_NO_MFA" -gt 0 ]; then
        print_result "WARN" "$USERS_NO_MFA user(s) without MFA enabled"
    else
        print_result "PASS" "All users have MFA enabled"
    fi
    
    # Check for old access keys (>90 days)
    OLD_KEYS=$(echo "$CRED_REPORT" | awk -F',' 'NR>1 && $9=="true" {print $1}' | wc -l)
    if [ "$OLD_KEYS" -gt 0 ]; then
        print_result "WARN" "$OLD_KEYS access key(s) older than 90 days"
    else
        print_result "PASS" "No access keys older than 90 days"
    fi
else
    print_result "WARN" "Unable to generate credential report"
fi

echo ""

# ==========================================
# 3. VPC FLOW LOGS CHECK
# ==========================================
echo "======================================"
echo "3. VPC Flow Logs"


VPCS=$(aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text 2>/dev/null)
if [ -z "$VPCS" ]; then
    print_result "WARN" "No VPCs found"
else
    for VPC in $VPCS; do
        FLOW_LOGS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC" --query 'FlowLogs' --output text 2>/dev/null)
        if [ -z "$FLOW_LOGS" ]; then
            print_result "FAIL" "VPC Flow Logs not enabled for $VPC"
        else
            print_result "PASS" "VPC Flow Logs enabled for $VPC"
        fi
    done
fi

echo ""

# ==========================================
# 4. CLOUDTRAIL CHECK
# ==========================================
echo "======================================"
echo "4. CloudTrail"

TRAILS=$(aws cloudtrail describe-trails --query 'trailList' --output json 2>/dev/null)
if [ "$TRAILS" == "[]" ] || [ -z "$TRAILS" ]; then
    print_result "FAIL" "No CloudTrail trails configured"
else
    TRAIL_COUNT=$(echo "$TRAILS" | grep -c '"Name"')
    print_result "PASS" "$TRAIL_COUNT CloudTrail trail(s) configured"
    
    # Check if trails are logging
    for TRAIL_NAME in $(echo "$TRAILS" | grep '"Name"' | cut -d'"' -f4); do
        TRAIL_STATUS=$(aws cloudtrail get-trail-status --name "$TRAIL_NAME" 2>/dev/null)
        if echo "$TRAIL_STATUS" | grep -q '"IsLogging": true'; then
            print_result "PASS" "  Trail '$TRAIL_NAME' is actively logging"
        else
            print_result "FAIL" "  Trail '$TRAIL_NAME' is NOT logging"
        fi
    done
fi

echo ""

# ==========================================
# 5. SECURITY GROUPS CHECK
# ==========================================
echo "======================================"
echo "5. Security Groups"

# Check for security groups with 0.0.0.0/0 access on sensitive ports
OPEN_SSH=$(aws ec2 describe-security-groups --filters "Name=ip-permission.from-port,Values=22" "Name=ip-permission.cidr,Values=0.0.0.0/0" --query 'SecurityGroups[].GroupId' --output text 2>/dev/null | wc -w)
OPEN_RDP=$(aws ec2 describe-security-groups --filters "Name=ip-permission.from-port,Values=3389" "Name=ip-permission.cidr,Values=0.0.0.0/0" --query 'SecurityGroups[].GroupId' --output text 2>/dev/null | wc -w)

if [ "$OPEN_SSH" -gt 0 ]; then
    print_result "FAIL" "$OPEN_SSH security group(s) with SSH (22) open to 0.0.0.0/0"
else
    print_result "PASS" "No security groups with SSH open to internet"
fi

if [ "$OPEN_RDP" -gt 0 ]; then
    print_result "FAIL" "$OPEN_RDP security group(s) with RDP (3389) open to 0.0.0.0/0"
else
    print_result "PASS" "No security groups with RDP open to internet"
fi

echo ""

# ==========================================
# SUMMARY
# ==========================================
echo "======================================"
echo "Audit Summary"
echo "======================================"
echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "${YELLOW}Warnings:${NC} $WARN_COUNT"
echo -e "${RED}Failed:${NC} $FAIL_COUNT"
echo ""
echo "Total Issues: $((WARN_COUNT + FAIL_COUNT))"
echo ""
echo "Completed: $(date)"
echo "======================================"

# Exit with error if there are failures
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
