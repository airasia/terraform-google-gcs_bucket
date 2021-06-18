Terraform module for storage bucket in GCP

# Upgrade guide from v2.4.1 to v2.5.0

This upgrade will rename the load-balancer resource(s) for them to be coherently identifiable in the GCP console as **Bucket LB** resource(s) which helps for faster troubleshooting.

1. First, ensure that you have applied `v2.4.1` of this module before proceeding.
2. Then upgrade `gcs_bucket` module version from `2.4.1` to `2.5.0`
3. Run `terraform plan` - **DO NOT APPLY** this plan yet.
4. If your bucket module at `v2.4.1` had `var.create_bucket_lb = true` (this value was automatically set to `true` for domain-named-buckets), then you maybe seeing several changes being planned by terraform here. Otherwise, you **SHOULD NOT** see any changes for your module in this plan. If you **STILL** see any changes being planned here, then please ensure that you have first reconciled and applied `v2.4.1` properly before proceeding with the next steps.
5. Ensure that the changes being planned by terraform for `v2.5.0` are **ONLY for** the following 6 resources and nothing more than that:
   1. **google_compute_backend_bucket.bucket_backend[0]**
      1. renames from `backend-bucket-___` to `bucket-backend-___"`
   2. **google_compute_global_address.lb_ip[0]**
      1. renames from `lb-ip-___` to `bucket-lbip-___"` - **_⚠️_ we will revisit this change in coming steps**
   3. **google_compute_global_forwarding_rule.fw_rule[0]**
      1. changes `ip_address` - **_⚠️_ we will revisit this change in coming steps**
      2. renames from `forwarding-rule-___` to `bucket-fwd-rule-___"`
   4. **google_compute_managed_ssl_certificate.mcrt[0]**
      1. renames from `cert-___` to `bucket-cert-___"`
   5. **google_compute_target_https_proxy.https_proxy[0]**
      1. renames from `https-proxy-___` to `bucket-proxy-___"`
   6. **google_compute_url_map.url_map[0]**
      1. renames from `lb-___` to `bucket-lb-___"`
6. Must not contain any other changes
   1. You **SHOULD NOT** see any other changes in this plan other than the 6 changes listed above. If you see _any other changes_, then please ensure that you have first reconciled and applied `v2.4.1` before proceeding with the rest of the steps.
   2. In the next steps, we will revisit the IP address changes (marked with ⚠️ above) for backward-compatibility.
7. Use the module variable called `lb_ip_name` to override the name change of the `lb_ip` resource.
   1. **NOTE:** This ability is provided only for backward-compatibility so that existing systems that maybe referring to this IP address (eg: DNS etc) do not break due to changes in this IP address.
   2. **RECOMMENDATION:** If you do not have any such systems depending on this IP address (or if you have the means of updating the IP address value in those systems) then we recommend you to not use this variable **at all**. Instead, go ahead with applying the changes presented in this plan and then update the IP address values in those external systems with the new IP address produced here.
      1. You can find the current IP address of the load-balancer from the output attribute called `lb_ip_address`.
8. After deciding between **7.1 vs 7.2**, run `terraform plan` again and inspect the plans being proposed.
   1. If you see **ANY OTHER CHANGES** than the ones elaborated above, then please ensure that you have first reconciled and applied `v2.4.1` and then repeat the above instructions before proceeding with the rest of the steps.
9. Run `terraform apply`
   1. The changes discussed above may take a maximum of 1 to 2 minutes.
10. If you decided to go with **option 7.2** above, remember to update your external systems (if any) with the new IP address produced here.
    1. You can find the current IP address of the load-balancer from the output attribute called `lb_ip_address`.
11. Done!

# Upgrade guide from v2.0.1 to v2.1.0

First make sure you've planned & applied `v2.0.1`. Then, upon upgrading from `v2.0.1` to `v2.1.0`, you may (or may not) see a plan that destroys & creates an equal number of `google_storage_bucket_iam_member` resources. It is OK to apply these changes as it will only change the data-structure of these resources [from an array to a hashmap](https://github.com/airasia/terraform-google-external_access/wiki/The-problem-of-%22shifting-all-items%22-in-an-array). Note that, after you plan & apply these changes, you may (or may not) get a **"Provider produced inconsistent result after apply"** error. Just re-plan and re-apply and that would resolve the error.
