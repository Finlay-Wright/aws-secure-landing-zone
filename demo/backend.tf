terraform {
  # Local state is fine for demo purposes
  # No need for S3 backend for a take-home challenge
  
  # If you really want to use remote state:
  # 1. Create an S3 bucket: aws s3 mb s3://your-terraform-state-bucket
  # 2. Uncomment the backend block below
  # 3. Run: terraform init -backend-config="bucket=your-bucket-name"
  
  # backend "s3" {
  #   bucket         = "terraform-state-demo"
  #   key            = "aws-baseline/demo/terraform.tfstate"
  #   region         = "eu-west-2"
  #   encrypt        = true
  #   # dynamodb_table = "terraform-locks"  # Optional: for state locking
  # }
}
