Activity 2: Creating a Basic Terraform Workflow

# Step 1: Create Github repository secrets 
For this activity, i use OIDC https://github.com/keengwatanabe/oidc
<!-- Go to your Github repository -> Settings
Go to Security > Secrets and Variables -> Actions
Click “New Repository Secret”
You will have to create 2 secrets with the following name:Name: AWS_ACCESS_KEY_ID
Value: Key in your Access Key ID value
Name: AWS_SECRET_ACCESS_KEY
Value: Key in your Secret Access Key ID value -->

# Step 2: Create your Terraform files
You may add any terraform resources as you like (Even a S3 bucket). However remember to `use a backend block to save your tfstate into a s3 bucket`.

provider "aws" {
  region = ""
}

terraform {
  backend "s3" {
    bucket = ""
    key    = ""
    region = ""
  }
}

# Step 3: Create your workflow file for creating resources via TF
Create a file called “terraform-apply.yaml” under the “./github/workflows” directory with the content below.
Push all of your changes to the main branch.

name: Terraform Deployment

on:
  push:
    branches: [ "main" ]

env:            
  AWS_REGION: us-east-1  

jobs:
  CICD:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3
   
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Verify AWS credentials
      run: |
        aws sts get-caller-identity


    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
   
    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan
   
    - name: Terraform Apply
      run: terraform apply --auto-approve

