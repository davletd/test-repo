
resource "aws_s3_bucket" "example" {
  bucket = "my-test-bucket"

  tags = {
    Environment = "Dev"
    Created     = "Via-API"
  }
}
