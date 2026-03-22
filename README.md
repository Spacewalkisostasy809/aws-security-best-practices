# AWS Security Best Practices

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Sections](https://img.shields.io/badge/sections-8-3ddc84)
![Docs](https://img.shields.io/badge/docs-28-5ccfe6)
![Audit Scripts](https://img.shields.io/badge/audit%20scripts-4-ffb454)
![Tested with moto](https://img.shields.io/badge/tested%20with-moto-ff6b6b)
![Terraform](https://img.shields.io/badge/terraform-vulnerable%20%26%20remediated-7b42bc)

A production-grade AWS security reference for DevOps and SRE engineers. Real attack scenarios, detection CLI commands, hardening checklists, runnable audit scripts, and Terraform environments to test against — both deliberately misconfigured and fully hardened.

> **Audience:** Mid-level DevOps/SRE engineers  
> **Style:** Scenario-driven — understand the attack, detect it, fix it

---

## What's in this repo

| Component | What it is |
|---|---|
| `docs/` | 28 markdown docs across 8 AWS security domains |
| `scripts/` | 4 audit shell scripts — run against any AWS account |
| `tests/` | Moto-based local test harness — no real AWS needed |
| `terraform/` | Vulnerable + remediated environments for real AWS testing |
| `index.html` | Interactive portfolio site — browsable terminal-style docs |

---

## Docs — 8 Sections

Each doc covers: attack scenario → detection CLI → fix CLI → checklist.

| # | Topic | What's Covered |
|---|-------|----------------|
| 01 | [IAM & Credentials](./docs/01-iam-credentials/README.md) | Static keys, role abuse, privilege escalation, Identity Center |
| 02 | [EC2 & Compute Security](./docs/02-ec2-compute/README.md) | IMDSv2 enforcement, instance roles, SSH → SSM Session Manager |
| 03 | [Network & VPC Security](./docs/03-network-vpc/README.md) | Security groups, VPC endpoints, flow logs |
| 04 | [CI/CD Pipeline Security](./docs/04-cicd-pipeline/README.md) | OIDC auth, secrets management, pipeline hardening |
| 05 | [S3 Security](./docs/05-s3/README.md) | Public access, bucket policies, encryption, ransomware defense |
| 06 | [Lambda Security](./docs/06-lambda/README.md) | Execution roles, env var secrets, function URLs, supply chain |
| 07 | [RDS & Database Security](./docs/07-rds/README.md) | Public access, IAM auth, encryption, audit logging |
| 08 | [Detection & Response](./docs/08-detection/README.md) | CloudTrail hardening, GuardDuty alerting, Security Hub |

---

## Audit Scripts

Four shell scripts that check a live AWS account for security misconfigurations. Exit code `1` on critical findings — safe to use as CI/CD pipeline gates.

```bash
git clone https://github.com/sharanch/aws-security-best-practices
cd aws-security-best-practices
chmod +x scripts/*.sh

bash scripts/audit-iam.sh     --profile my-profile --region ap-south-1
bash scripts/audit-ec2.sh     --profile my-profile --region ap-south-1
bash scripts/audit-network.sh --profile my-profile --region ap-south-1
bash scripts/audit-s3-rds.sh  --profile my-profile --region ap-south-1
```

| Script | Checks |
|--------|--------|
| `audit-iam.sh` | Root access keys, MFA, key age, admin access, dangerous trust policies, password policy, Access Analyzer, CloudTrail, GuardDuty |
| `audit-ec2.sh` | IMDSv2, public IPs, open SSH/RDP, overprivileged instance roles, SSM readiness, EBS encryption |
| `audit-network.sh` | VPC flow logs, VPC endpoints, default VPC, all-traffic SGs, S3 account BPA, CloudTrail |
| `audit-s3-rds.sh` | Bucket BPA/encryption/versioning/logging, public bucket policies, RDS public access/encryption/auth/backups, Lambda env var secrets and public URLs |

---

## Testing

### Option 1 — Local with moto (no AWS account needed)

```bash
# Requires: python3, aws-cli, curl
bash tests/test-all.sh
```

Starts a moto server, creates deliberately misconfigured resources, runs all 4 audit scripts, prints findings, shuts down. Verified output:

```
  FAILED  IAM Security Audit      — 5 critical,  3 warnings
  FAILED  EC2 Security Audit      — 4 critical,  5 warnings
  FAILED  Network Security Audit  — 4 critical,  6 warnings
  FAILED  S3 + RDS + Lambda Audit — 7 critical, 16 warnings

  Total critical: 20  |  Total warnings: 30
```

See [`tests/README.md`](./tests/README.md) for the full resource → finding mapping.

### Option 2 — Real AWS with Terraform (~$0.02/hr)

Two Terraform environments that provision real AWS resources:

```bash
# Deploy vulnerable — triggers all audit findings
cd terraform/vulnerable
terraform init && terraform apply -auto-approve

# Run audit scripts against real AWS
bash scripts/audit-iam.sh --region ap-south-1
bash scripts/audit-ec2.sh --region ap-south-1

# Deploy remediated — audit scripts should mostly pass
cd ../remediated
terraform init && terraform apply -auto-approve -var="db_password=StrongPass123!"

# Run audit scripts again — compare results
bash scripts/audit-iam.sh --region ap-south-1
bash scripts/audit-ec2.sh --region ap-south-1

# Destroy when done
terraform destroy -auto-approve
```

See [`terraform/README.md`](./terraform/README.md) for the full resource list, settings comparison table, and destroy instructions.

---

## Core Philosophy

```
Assume breach will happen.
Design so that when it does:
  - Blast radius is minimal
  - Detection is immediate
  - Recovery is fast
```

Every doc follows: **attack scenario → detection → fix → checklist**.

---

## Quick Reference

```bash
# Root account has no access keys (should return 0)
aws iam get-account-summary --query 'SummaryMap.AccountAccessKeysPresent'

# Find users with no MFA
aws iam get-credential-report --query 'Content' --output text | \
  base64 -d | cut -d',' -f1,4,8 | grep ',false'

# Find EC2 instances with IMDSv1 (should be empty)
aws ec2 describe-instances \
  --filters "Name=metadata-options.http-tokens,Values=optional" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Find security groups with SSH open to world
aws ec2 describe-security-groups \
  --filters "Name=ip-permission.from-port,Values=22" \
            "Name=ip-permission.cidr,Values=0.0.0.0/0" \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table

# Find publicly accessible RDS instances
aws rds describe-db-instances \
  --query 'DBInstances[?PubliclyAccessible==`true`].[DBInstanceIdentifier,Engine]' \
  --output table
```

---

## Repo Structure

```
aws-security-best-practices/
├── README.md
├── LICENSE
├── index.html                       ← Interactive portfolio site
├── .github/workflows/deploy.yml     ← Auto-deploys to GitHub Pages
├── docs/
│   ├── 01-iam-credentials/          ← 4 docs
│   ├── 02-ec2-compute/              ← 3 docs
│   ├── 03-network-vpc/              ← 3 docs
│   ├── 04-cicd-pipeline/            ← 3 docs
│   ├── 05-s3/                       ← 3 docs
│   ├── 06-lambda/                   ← 3 docs
│   ├── 07-rds/                      ← 3 docs
│   └── 08-detection/                ← 3 docs
├── scripts/
│   ├── audit-iam.sh
│   ├── audit-ec2.sh
│   ├── audit-network.sh
│   └── audit-s3-rds.sh
├── terraform/
│   ├── modules/                     ← iam, ec2, s3, rds, lambda
│   ├── vulnerable/                  ← misconfigured resources
│   └── remediated/                  ← hardened resources
└── tests/
    ├── test-all.sh                  ← one-command moto test runner
    ├── setup_vulnerable_env.py      ← creates misconfigured resources
    └── run-audit-local.sh           ← runs all 4 scripts against moto
```

---

## License

[MIT License](./LICENSE) — free to use, share, and adapt with attribution.

---

## Contributing

PRs welcome. Follow the existing format:

1. Attack scenario first
2. Detection CLI commands
3. Fix CLI commands
4. Checklist at the end
5. If adding a new test resource — update `tests/setup_vulnerable_env.py`, `tests/README.md`, and the relevant Terraform module