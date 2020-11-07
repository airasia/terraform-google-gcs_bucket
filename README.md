Terraform module for storage bucket in GCP

# Upgrade guide from v2.0.1 to v2.1.0

First make sure you've planned & applied `v2.0.1`. Then, upon upgrading from `v2.0.1` to `v2.1.0`, you may (or may not) see a plan that destroys & creates an equal number of `google_storage_bucket_iam_member` resources. It is OK to apply these changes as it will only change the data-structure of these resources [from an array to a hashmap](https://github.com/airasia/terraform-google-external_access/wiki/The-problem-of-%22shifting-all-items%22-in-an-array). Note that, after you plan & apply these changes, you may (or may not) get a **"Provider produced inconsistent result after apply"** error. Just re-plan and re-apply and that would resolve the error.
