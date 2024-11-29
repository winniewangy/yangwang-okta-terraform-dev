resource "okta_user" "tf_test_user" {
  first_name = var.user_first_name
  last_name = var.user_last_name
  login = var.user_login_email
  email = var.user_login_email
}