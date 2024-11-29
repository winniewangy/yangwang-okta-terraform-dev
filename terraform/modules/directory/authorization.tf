resource "okta_auth_server" "api_server" {
  audiences   = ["api://api_server.mycompany.com"]
  description = "My Custom API Auth Server"
  name        = "api_server"
  issuer_mode = "DYNAMIC"
  status      = "ACTIVE"
}