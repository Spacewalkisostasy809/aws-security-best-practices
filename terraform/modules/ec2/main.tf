locals {
  prefix = "audit-test-${var.environment}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ── Security Group ─────────────────────────────────────────────────────────────
# VULNERABLE:  SSH open to 0.0.0.0/0
# REMEDIATED:  no SSH rule — use SSM Session Manager instead
resource "aws_security_group" "instance_sg" {
  name        = "${local.prefix}-instance-sg"
  description = "Audit test - ${var.environment}"
  vpc_id      = var.vpc_id

  # VULNERABLE: SSH open to world — triggers audit-ec2.sh finding
  dynamic "ingress" {
    for_each = var.allow_ssh_from_world ? [1] : []
    content {
      description = "SSH from anywhere — INSECURE"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # REMEDIATED: no inbound rules — SSM Session Manager needs no open ports
  egress {
    description = "Allow outbound HTTPS for SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Purpose = "audit-test"
    Risk    = var.allow_ssh_from_world ? "HIGH - SSH open to world" : "LOW - no open inbound ports"
  }
}

# ── IAM Instance Role ──────────────────────────────────────────────────────────
# VULNERABLE:  AdministratorAccess on instance role
# REMEDIATED:  minimal SSM permissions only
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "${local.prefix}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Purpose = "audit-test"
    Risk    = var.attach_admin_role ? "CRITICAL - AdministratorAccess" : "LOW - minimal permissions"
  }
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  # VULNERABLE: AdministratorAccess — any process on instance = full AWS access
  count      = var.attach_admin_role ? 1 : 0
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  # REMEDIATED: only SSM core permissions — enables Session Manager, nothing else
  count      = var.attach_admin_role ? 0 : 1
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${local.prefix}-instance-profile"
  role = aws_iam_role.instance_role.name
}

# ── EC2 Instance ───────────────────────────────────────────────────────────────
# VULNERABLE:  IMDSv1, unencrypted root volume
# REMEDIATED:  IMDSv2 required, encrypted root volume, SSM only
resource "aws_instance" "test_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  # VULNERABLE: optional = IMDSv1 allowed (SSRF credential theft vector)
  # REMEDIATED: required = IMDSv2 only
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enforce_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    # VULNERABLE: encrypted = false
    # REMEDIATED: encrypted = true with KMS
    encrypted   = var.encrypt_ebs
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name    = "${local.prefix}-instance"
    Purpose = "audit-test"
    Risk = join(", ", compact([
      !var.enforce_imdsv2 ? "IMDSv1-enabled" : "",
      var.allow_ssh_from_world ? "SSH-open" : "",
      var.attach_admin_role ? "AdminRole" : "",
      !var.encrypt_ebs ? "unencrypted-EBS" : "",
    ]))
  }
}

# ── Unencrypted EBS Volume ────────────────────────────────────────────────────
# VULNERABLE:  additional unencrypted volume
# REMEDIATED:  not created (or encrypted)
resource "aws_ebs_volume" "test_volume" {
  availability_zone = aws_instance.test_instance.availability_zone
  size              = 1
  encrypted         = var.encrypt_ebs

  tags = {
    Name    = "${local.prefix}-ebs"
    Purpose = "audit-test"
    Risk    = var.encrypt_ebs ? "LOW - encrypted" : "HIGH - unencrypted"
  }
}
