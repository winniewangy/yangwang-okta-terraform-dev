resource "okta_user" "passwordless_test_user" {
  first_name = "Terraform"
  last_name = "TestUser"
  login = "tfstestuser@example.com"
  email = "tftestuser@example.com"
}