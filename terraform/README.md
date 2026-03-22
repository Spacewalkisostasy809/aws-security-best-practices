# Terraform

Provisions real AWS resources to test the audit scripts against actual AWS — not moto. Two independent environments: `vulnerable/` and `remediated/`. Apply one, run the audit scripts, see the difference.

> **Cost:** ~$0.02/hr per environment. RDS (`db.t3.micro`) is the only non-free resource at ~$0.017/hr. Destroy when done.

---

## Structure

```
terraform/
├── provider.tf              ← AWS provider and backend config (kept separate)
├── variables.tf             ← shared variables
├── outputs.tf               ← shared outputs
├── modules/
│   ├── iam/                 ← users, roles, trust policies, password policy
│   ├── ec2/                 ← instance, security group, EBS, IAM role
│   ├── s3/                  ← bucket, block public access, encryption, versioning, policy
│   ├── rds/                 ← RDS instance, subnet group, security group
│   └── lambda/              ← function, execution role, function URL
├── vulnerable/              ← calls all modules with bad settings
└── remediated/              ← calls all modules with secure settings
```

Each module accepts boolean variables that flip between secure and insecure config. The `vulnerable/` and `remediated/` roots call the same modules with opposite values — so the diff between the two is just boolean flags.

---

## Prerequisites

```bash
# Terraform >= 1.5.0
terraform -version

# AWS CLI with credentials
aws sso login --profile my-profile
export AWS_PROFILE=my-profile
export AWS_DEFAULT_REGION=ap-south-1
```

---

## Vulnerable Environment

Deploys misconfigured resources that trigger findings in all 4 audit scripts.

### Resources created (20)

**IAM**
- `audit-test-vulnerable-user` — active access key, no MFA
- `audit-test-vulnerable-admin-user` — AdministratorAccess attached directly to user
- `audit-test-vulnerable-dangerous-trust-role` — `Principal: *` in trust policy
- `audit-test-vulnerable-instance-role` — AdministratorAccess on EC2 role
- `audit-test-vulnerable-lambda-role` — AdministratorAccess on Lambda role
- No account password policy

**EC2**
- `audit-test-vulnerable-instance-sg` — SSH (22) and all traffic open to `0.0.0.0/0`
- `audit-test-vulnerable-instance` — IMDSv1 enabled, unencrypted root EBS
- `audit-test-vulnerable-ebs` — 1GB unencrypted volume

**S3**
- `audit-test-vulnerable-bucket-{account_id}` — Block Public Access disabled, no encryption, no versioning
- Bucket policy with `Principal: *` — anyone can read objects

**RDS**
- `audit-test-vulnerable-rds-sg` — port 3306 open to `0.0.0.0/0`
- `audit-test-vulnerable-db-subnet-group`
- `audit-test-vulnerable-db` — publicly accessible, unencrypted, no backups, IAM auth off, deletion protection off

**Lambda**
- `audit-test-vulnerable-function` — `DB_PASSWORD`, `API_KEY`, `STRIPE_SECRET` in env vars
- `audit-test-vulnerable-function` URL — `AuthType: NONE` (public invocation)

### Apply

```bash
cd terraform/vulnerable
terraform init
terraform plan
terraform apply -auto-approve
```

### Run audit scripts

```bash
cd ../..
bash scripts/audit-iam.sh     --region ap-south-1
bash scripts/audit-ec2.sh     --region ap-south-1
bash scripts/audit-network.sh --region ap-south-1
bash scripts/audit-s3-rds.sh  --region ap-south-1
```

### Expected findings

```
[CRITICAL] User 'audit-test-vulnerable-admin-user' has AdministratorAccess attached directly
[CRITICAL] Role 'audit-test-vulnerable-dangerous-trust-role' has Principal: * in trust policy
[CRITICAL] No account password policy set
[CRITICAL] Instance i-xxxx (audit-test-vulnerable-instance) has IMDSv1 enabled
[CRITICAL] Security group sg-xxxx (audit-test-vulnerable-instance-sg) has SSH open to 0.0.0.0/0
[CRITICAL] Bucket 'audit-test-vulnerable-bucket-*' has Principal: * with no conditions
[CRITICAL] RDS instance audit-test-vulnerable-db is PUBLICLY ACCESSIBLE
[CRITICAL] RDS instance audit-test-vulnerable-db is NOT encrypted at rest
[CRITICAL] RDS audit-test-vulnerable-db automated backups are DISABLED
[WARNING]  Lambda 'audit-test-vulnerable-function' has suspicious env vars: DB_PASSWORD, API_KEY
[CRITICAL] Lambda 'audit-test-vulnerable-function' has a public URL with AuthType NONE
```

### Destroy

```bash
cd terraform/vulnerable
terraform destroy -auto-approve
```

---

## Remediated Environment

Same resources, every security setting flipped to best practice. Audit scripts should produce mostly `[PASS]`.

### Resources created (19)

Same as vulnerable with these differences:
- No static access key on user — SSO used instead
- MFA enforced via deny-without-MFA IAM policy
- Trust policy scoped to specific account + `sts:ExternalId` condition
- Strong account password policy (14 char min, 90-day rotation)
- IMDSv2 required on EC2
- No SSH open — SSM Session Manager used instead
- EBS volumes encrypted
- EC2 role has `AmazonSSMManagedInstanceCore` only
- S3 Block Public Access fully enabled, AES256 encryption, versioning enabled
- S3 bucket policy: account-only + HTTPS enforced
- RDS private, encrypted, 7-day backups, IAM auth enabled, deletion protection enabled
- Lambda has no secrets in env vars — `SECRETS_ARN` points to Secrets Manager
- No Lambda public URL — use API Gateway with IAM auth instead
- Lambda role has `AWSLambdaBasicExecutionRole` only

### Apply

```bash
cd terraform/remediated
terraform init
terraform plan -var="db_password=YourStrongPassword123!"
terraform apply -auto-approve -var="db_password=YourStrongPassword123!"
```

### Run audit scripts

```bash
cd ../..
bash scripts/audit-iam.sh     --region ap-south-1
bash scripts/audit-ec2.sh     --region ap-south-1
bash scripts/audit-network.sh --region ap-south-1
bash scripts/audit-s3-rds.sh  --region ap-south-1
```

### Destroy

RDS has `deletion_protection = true` in the remediated environment. Terraform cannot destroy it directly — disable it first:

```bash
aws rds modify-db-instance \
  --db-instance-identifier audit-test-remediated-db \
  --no-deletion-protection \
  --apply-immediately

# Wait ~30 seconds, then:
terraform destroy -auto-approve -var="db_password=anything"
```

---

## Settings comparison

| Setting | Vulnerable | Remediated |
|---|---|---|
| Static access key | created | not created |
| MFA enforcement | none | deny-without-MFA policy |
| IAM trust policy | `Principal: *` | specific account + ExternalId |
| Password policy | not set | 14 char min, 90-day rotation |
| IMDSv2 | `optional` | `required` |
| SSH access | `0.0.0.0/0` | no inbound — SSM only |
| EC2 role | AdministratorAccess | AmazonSSMManagedInstanceCore |
| EBS encryption | `false` | `true` |
| S3 Block Public Access | all `false` | all `true` |
| S3 encryption | none | AES256 |
| S3 versioning | Suspended | Enabled |
| S3 bucket policy | `Principal: *` | account-only + HTTPS |
| RDS public access | `true` | `false` |
| RDS encryption | `false` | `true` |
| RDS backups | 0 days | 7 days |
| RDS IAM auth | `false` | `true` |
| RDS deletion protection | `false` | `true` |
| Lambda env vars | plaintext secrets | SECRETS_ARN reference only |
| Lambda URL | `AuthType: NONE` | not created |
| Lambda role | AdministratorAccess | AWSLambdaBasicExecutionRole |

---

## Cost estimate

| Resource | Type | Per hour |
|---|---|---|
| EC2 | `t3.micro` | Free tier |
| EBS | 1GB `gp3` | ~$0.001 |
| RDS | `db.t3.micro` | ~$0.017 |
| S3 | empty bucket | Free |
| Lambda | no invocations | Free |

**1 hour:** ~$0.02 per environment  
**Overnight (8 hrs):** ~$0.15 per environment

RDS takes ~5 minutes to provision and ~5 minutes to destroy. Everything else is under 30 seconds.