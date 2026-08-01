# Remote state, stored in OCI Object Storage (S3-compatible API, free tier: 20GB).
# This matters for the same reason companies never keep state locally:
# no single laptop is a source of truth, and state locking prevents
# two people (or two CI runs) from applying at the same time.
#
# SETUP (one-time, do this BEFORE `terraform init`):
#   1. OCI Console -> Storage -> Buckets -> create bucket "terraform-state"
#   2. OCI Console -> Identity -> Customer Secret Keys -> generate one
#      (this gives you an S3-compatible access_key / secret_key pair)
#   3. Fill in the values below or pass via -backend-config flags so you
#      never commit real keys to git.

# terraform {
#  backend "s3" {
 #   bucket                      = "terraform-state"
  #  key                         = "mega-devops/cluster/terraform.tfstate"
   # region                      = "ap-hyderabad-1" # match your OCI region
    #endpoints                    = {
   #      s3 = "https://axjyt8wcwdvg.compat.objectstorage.ap-hyderabad-1.oraclecloud.com"
  # }
   # skip_region_validation      = true
    #skip_credentials_validation = true
   # skip_metadata_api_check     = true
   # skip_requesting_account_id  = true
   # use_path_style            = true
    # access_key / secret_key intentionally NOT hardcoded here.
    # Export as env vars instead:
    #   export AWS_ACCESS_KEY_ID=<customer-secret-key-id>
    #   export AWS_SECRET_ACCESS_KEY=<customer-secret-key-secret>
#  }
 # }
