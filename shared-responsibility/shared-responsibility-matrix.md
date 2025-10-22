# AWS Shared Responsibility Model Matrix

## Overview
The AWS Shared Responsibility Model defines the division of security responsibilities between AWS and the customer. AWS is responsible for "Security OF the Cloud" while customers are responsible for "Security IN the Cloud."

## Responsibility Matrix

| Service | AWS Responsibility | Customer Responsibility |
|---------|-------------------|------------------------|
| **EC2** | • Physical infrastructure security<br>• Hypervisor and virtualization layer<br>• Network infrastructure<br>• Hardware maintenance<br>• Physical data center security | • Operating system patches and updates<br>• Application software and utilities<br>• Security group configuration<br>• Network ACLs<br>• IAM roles and policies<br>• Data encryption (at rest and in transit)<br>• Firewall configuration |
| **RDS** | • Database software patching<br>• Operating system maintenance<br>• Hardware infrastructure<br>• Automated backups<br>• High availability infrastructure<br>• Physical security | • Database user management<br>• Database access controls<br>• Network configuration (VPC, security groups)<br>• Encryption configuration<br>• Backup retention policies<br>• Parameter group configuration<br>• IAM database authentication |
| **S3** | • Infrastructure and facilities<br>• Storage durability (11 9's)<br>• Hardware and network<br>• Global infrastructure<br>• Service availability<br>• Replication infrastructure | • Bucket policies and permissions<br>• Object ACLs<br>• Encryption configuration (SSE-S3, SSE-KMS, SSE-C)<br>• Versioning configuration<br>• Lifecycle policies<br>• Access logging<br>• Data classification and protection |
| **Lambda** | • Function execution environment<br>• Operating system maintenance<br>• Capacity provisioning<br>• Automatic scaling<br>• Code execution infrastructure<br>• Patching runtime environment | • Function code security<br>• IAM execution roles<br>• Environment variables (including secrets)<br>• VPC configuration<br>• Function permissions<br>• Dependency management<br>• Application-level logging |
| **ECS/Fargate** | • Container orchestration platform<br>• Infrastructure management<br>• Fargate: OS and runtime patching<br>• Control plane security<br>• Physical infrastructure | • Container images security<br>• Task definitions<br>• IAM roles for tasks<br>• Network configuration<br>• Secrets management<br>• Application code<br>• EC2 mode: OS patching and management |
| **VPC** | • Network infrastructure<br>• Physical network devices<br>• Availability Zone infrastructure<br>• Region connectivity<br>• DDoS protection (infrastructure layer) | • Subnet design and configuration<br>• Route table configuration<br>• Network ACLs<br>• Security groups<br>• VPN configuration<br>• VPC peering<br>• Flow logs configuration<br>• NAT Gateway/Instance management |
| **IAM** | • Identity infrastructure<br>• Authentication system<br>• Service availability<br>• Global identity management<br>• MFA token validation | • User and group management<br>• Policy creation and management<br>• Access key rotation<br>• Password policies<br>• MFA enforcement<br>• Role creation and assignment<br>• Principle of least privilege implementation |
| **CloudFront** | • Edge location infrastructure<br>• Content delivery network<br>• DDoS protection (AWS Shield Standard)<br>• Physical security<br>• Global network | • Origin configuration<br>• Cache behavior settings<br>• SSL/TLS certificates<br>• Access restrictions (signed URLs/cookies)<br>• WAF rules configuration<br>• Geo-restriction settings<br>• Custom error pages |
| **DynamoDB** | • Hardware infrastructure<br>• Software patching<br>• Replication and backup infrastructure<br>• Availability and durability<br>• Scaling infrastructure | • Table design and schema<br>• Access control (IAM policies)<br>• Encryption at rest configuration<br>• Point-in-time recovery settings<br>• Global table configuration<br>• DynamoDB Streams management<br>• Application-level data validation |
| **EBS** | • Physical storage infrastructure<br>• Hardware maintenance<br>• Replication within AZ<br>• Snapshot infrastructure<br>• Volume durability | • Volume encryption configuration<br>• Snapshot management and retention<br>• Access control (IAM)<br>• Data backup strategy<br>• Volume attachment to EC2<br>• Data on volumes<br>• Snapshot sharing permissions |

## Key Principles

### AWS Responsibilities (Security OF the Cloud)
- Physical infrastructure and facilities
- Hardware and global network
- Virtualization infrastructure
- Managed service operations
- Compliance certifications for infrastructure

### Customer Responsibilities (Security IN the Cloud)
- Data encryption and protection
- Identity and access management
- Network traffic protection
- Operating system and application security
- Firewall configuration
- Compliance validation for applications

## Security Best Practices

1. **Implement Defense in Depth**: Use multiple layers of security controls
2. **Principle of Least Privilege**: Grant minimum necessary permissions
3. **Enable Logging and Monitoring**: Use CloudTrail, VPC Flow Logs, and CloudWatch
4. **Encrypt Data**: At rest and in transit
5. **Automate Security**: Use Infrastructure as Code and automated compliance checks
6. **Regular Audits**: Conduct security assessments and penetration testing
7. **Incident Response Plan**: Prepare for security incidents
8. **Patch Management**: Keep systems and applications updated

## References
- [AWS Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
