# Amazon S3 Cost Analysis

## Overview
This document provides a comprehensive analysis of Amazon S3 pricing across three major AWS regions, focusing on Standard storage class pricing, data transfer costs, and estimated monthly costs for storing 100GB of data.

## Regions Analyzed
- **US East (N. Virginia) - us-east-1**
- **Asia Pacific (Singapore) - ap-southeast-1** 
- **Europe (Ireland) - eu-west-1**

## Standard S3 Storage Pricing by Region

### US East (N. Virginia) - us-east-1
- **First 50 TB/month**: $0.023 per GB
- **Next 450 TB/month**: $0.022 per GB
- **Over 500 TB/month**: $0.021 per GB

### Asia Pacific (Singapore) - ap-southeast-1
- **First 50 TB/month**: $0.025 per GB
- **Next 450 TB/month**: $0.024 per GB
- **Over 500 TB/month**: $0.023 per GB

### Europe (Ireland) - eu-west-1
- **First 50 TB/month**: $0.023 per GB
- **Next 450 TB/month**: $0.022 per GB
- **Over 500 TB/month**: $0.021 per GB

## Estimated Monthly Cost for 100GB Storage

### Storage Costs (100GB in Standard class)
| Region | Monthly Storage Cost |
|--------|---------------------|
| US East (N. Virginia) | $2.30 |
| Asia Pacific (Singapore) | $2.50 |
| Europe (Ireland) | $2.30 |

### Request Pricing (per 1,000 requests)
| Request Type | US East | Asia Pacific (Singapore) | Europe (Ireland) |
|-------------|---------|--------------------------|------------------|
| PUT, COPY, POST, LIST | $0.0005 | $0.0005 | $0.0005 |
| GET, SELECT | $0.0004 | $0.0004 | $0.0004 |

### Estimated Monthly Requests Cost (100GB with moderate usage)
Assuming:
- 1,000 PUT requests per month
- 10,000 GET requests per month

| Region | PUT Requests | GET Requests | Total Requests Cost |
|--------|-------------|-------------|-------------------|
| US East (N. Virginia) | $0.50 | $4.00 | $4.50 |
| Asia Pacific (Singapore) | $0.50 | $4.00 | $4.50 |
| Europe (Ireland) | $0.50 | $4.00 | $4.50 |

### Total Monthly Cost (Storage + Requests)
| Region | Storage | Requests | **Total** |
|--------|---------|----------|-----------|
| US East (N. Virginia) | $2.30 | $4.50 | **$6.80** |
| Asia Pacific (Singapore) | $2.50 | $4.50 | **$7.00** |
| Europe (Ireland) | $2.30 | $4.50 | **$6.80** |

## Data Transfer Costs Between Regions

### Data Transfer OUT from S3 to Internet
| Region | First 1 GB/month | Up to 10 TB/month | Next 40 TB/month | Next 100 TB/month |
|--------|------------------|-------------------|------------------|-------------------|
| US East (N. Virginia) | Free | $0.09/GB | $0.085/GB | $0.070/GB |
| Asia Pacific (Singapore) | Free | $0.12/GB | $0.085/GB | $0.070/GB |
| Europe (Ireland) | Free | $0.09/GB | $0.085/GB | $0.070/GB |

### Cross-Region Data Transfer
| Transfer Route | Cost per GB |
|---------------|-------------|
| US East → Asia Pacific (Singapore) | $0.02 |
| US East → Europe (Ireland) | $0.02 |
| Asia Pacific (Singapore) → US East | $0.02 |
| Asia Pacific (Singapore) → Europe (Ireland) | $0.02 |
| Europe (Ireland) → US East | $0.02 |
| Europe (Ireland) → Asia Pacific (Singapore) | $0.02 |

### Data Transfer IN to S3
- **From Internet**: Free for all regions
- **From AWS services in same region**: Free
- **From AWS services in different regions**: $0.01-$0.02 per GB

## Key Pricing Observations

### 1. Regional Pricing Variations
- **Asia Pacific (Singapore) has higher storage costs** ($0.025/GB vs $0.023/GB)
- **Internet egress costs are higher** in Asia Pacific region ($0.12/GB vs $0.09/GB)
- Request pricing remains consistent across all regions

### 2. Data Transfer Cost Considerations
- **Cross-region transfers** incur $0.02/GB regardless of direction
- **Internet egress** costs are the same across regions but can be significant for high-traffic applications
- **Inbound transfers** from internet are free, encouraging data ingestion

### 3. Cost Optimization Opportunities
- **Intelligent-Tiering**: Automatic cost optimization for varying access patterns
- **Lifecycle policies**: Transition to cheaper storage classes (IA, Glacier) for infrequently accessed data
- **Transfer Acceleration**: May reduce transfer times but adds cost ($0.04-$0.08/GB)

### 4. Hidden Costs to Consider
- **Monitoring and management**: CloudWatch metrics, S3 Storage Lens
- **Security features**: GuardDuty Malware Protection, Access Logging
- **Compliance**: Object Lock, versioning storage overhead

## Recommendations

### For 100GB Storage Scenario
1. **Region Selection**: Choose based on latency to users rather than cost (pricing is identical)
2. **Request Optimization**: Batch operations to reduce request costs
3. **Lifecycle Management**: Implement policies for data older than 30 days
4. **Monitoring**: Use S3 Storage Lens to identify optimization opportunities

### For Multi-Region Deployments
1. **Replication Strategy**: Consider costs of Cross-Region Replication ($0.015/GB + storage)
2. **Multi-Region Access Points**: Simplify architecture but monitor data transfer costs
3. **Edge Optimization**: Use CloudFront for frequently accessed content

## Cost Calculation Tools
- **AWS Pricing Calculator**: https://calculator.aws
- **S3 Storage Lens**: Built-in cost analysis and recommendations
- **AWS Cost Explorer**: Historical cost analysis and forecasting

---

*Note: This analysis focuses on Standard storage class and does not include costs for other storage classes, advanced features, or third-party integrations.*