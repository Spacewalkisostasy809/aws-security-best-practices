# Local Audit Testing with Moto

Test all 4 audit scripts against a deliberately misconfigured AWS environment — no real AWS account or free tier needed. Uses [moto](https://github.com/getmoto/moto) to mock AWS services locally inside a Python virtual environment.

---

## Requirements

- `python3` with `venv` support
- `aws` CLI v2
- `curl`

No pip packages need to be installed manually — `test-all.sh` handles everything inside a venv at `tests/.venv`.

---

## How it works

```
bash tests/test-all.sh
    │
    ├── creates tests/.venv  (python3 -m venv)
    ├── activates venv
    ├── pip install moto + boto3 into venv
    │
    ├── starts moto_server on localhost:5000 (from venv)
    │
    ├── setup_vulnerable_env.py
    │     creates misconfigured resources in moto:
    │     ├── IAM:     users without MFA, admin access, dangerous trust policies
    │     ├── EC2:     IMDSv1 instances, open SSH/RDP/all-traffic security groups, unencrypted EBS
    │     ├── Network: VPCs without flow logs, no VPC endpoints
    │     ├── S3:      public buckets, no encryption, no versioning
    │     ├── RDS:     publicly accessible, unencrypted, no backups
    │     └── Lambda:  secrets in env vars, public URLs
    │
    ├── run-audit-local.sh
    │     sets AWS_ENDPOINT_URL=http://localhost:5000
    │     runs all 4 audit scripts against moto:
    │     ├── audit-iam.sh
    │     ├── audit-ec2.sh
    │     ├── audit-network.sh
    │     └── audit-s3-rds.sh
    │
    └── stops moto_server, deactivates venv
```

---

## Run

```bash
# One command — does everything including venv setup
bash tests/test-all.sh
```

The venv is created once at `tests/.venv` and reused on subsequent runs. Dependencies are reinstalled on each run to stay current with `requirements.txt`.

---

## Step by step (if you want to inspect between stages)

```bash
# 1. Set up and activate the venv manually
python3 -m venv tests/.venv
source tests/.venv/bin/activate
pip install -r tests/requirements.txt

# 2. Start moto in one terminal
moto_server -p 5000

# 3. In another terminal — activate venv and set env vars
source tests/.venv/bin/activate
export AWS_ENDPOINT_URL=http://localhost:5000
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=ap-south-1
export AWS_PAGER=""

# 4. Create the vulnerable resources
python3 tests/setup_vulnerable_env.py

# 5. Inspect what was created
aws iam list-users
aws iam list-roles --query 'Roles[*].RoleName' --output table
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,MetadataOptions.HttpTokens]' --output table
aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
aws s3api list-buckets
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,PubliclyAccessible,StorageEncrypted]' --output table

# 6. Run the audits
bash tests/run-audit-local.sh

# 7. Deactivate when done
deactivate
```

---

## Expected output

```
══════════════════════════════════════════
  OVERALL RESULTS
══════════════════════════════════════════
  FAILED  IAM Security Audit      — 5 critical, 3 warnings
  FAILED  EC2 Security Audit      — 4 critical, 5 warnings
  FAILED  Network Security Audit  — 4 critical, 6 warnings
  FAILED  S3 + RDS + Lambda Audit — 7 critical, 16 warnings

  Total critical: 20
  Total warnings: 30

Vulnerable environment confirmed — 20 critical findings detected.
These are expected — this is a deliberately misconfigured test environment.
```

All findings are intentional. If a script produces zero findings something is broken, not working correctly.

---

## Resource → finding mapping

| Resource created | Script | Finding triggered |
|---|---|---|
| `test-no-mfa-user` | audit-iam | User has active key, never used |
| `test-admin-user` | audit-iam | User has AdministratorAccess |
| `test-admin-group` | audit-iam | Group has AdministratorAccess |
| `test-dangerous-trust-role` | audit-iam | `Principal: *` in trust policy |
| `(default moto state)` | audit-iam | No password policy, no CloudTrail, no GuardDuty |
| `test-imdsv1-instance` | audit-ec2 | IMDSv1 enabled — SSRF credential theft vector |
| `test-open-ssh-sg` | audit-ec2 | SSH (22) open to `0.0.0.0/0` |
| `test-open-rdp-sg` | audit-ec2 | RDP (3389) open to `0.0.0.0/0` |
| `test-all-traffic-sg` | audit-ec2 + audit-network | All traffic open to `0.0.0.0/0` |
| `test-unencrypted-ebs` | audit-ec2 | EBS volume not encrypted |
| `test-no-flowlogs-vpc` | audit-network | VPC has no flow logs |
| `(default VPC)` | audit-network | Default VPC exists, no S3/STS endpoints |
| `test-audit-public-bucket` | audit-s3-rds | Bucket public via `Principal: *` policy |
| `test-audit-noenc-bucket` | audit-s3-rds | No encryption, no versioning, no logging |
| `test-audit-novers-bucket` | audit-s3-rds | Versioning disabled |
| `test-public-db` | audit-s3-rds | RDS publicly accessible, unencrypted, no backups |
| `test-public-enc-db` | audit-s3-rds | RDS publicly accessible, IAM auth off |
| `test-audit-lambda-secrets` | audit-s3-rds | Env vars contain `DB_PASSWORD`, `API_KEY`, `STRIPE_SECRET_KEY` |
| `test-audit-lambda-public-url` | audit-s3-rds | Lambda URL with `AuthType: NONE` |

---

## Notes on moto limitations

A few things moto handles differently from real AWS:

- **AWS managed policies** (`arn:aws:iam::aws:policy/...`) are not pre-loaded in moto. `setup_vulnerable_env.py` creates `AdministratorAccess` manually under the account ARN. The audit scripts check both ARN formats.
- **CloudTrail, GuardDuty, IAM Access Analyzer** are not enabled by default in moto — the audit scripts correctly flag their absence as findings.
- **SSM Agent** is not simulated — `audit-ec2.sh` will always warn that no instances have SSM Agent online in moto.
- The `.venv` directory is gitignored — never committed to the repo.