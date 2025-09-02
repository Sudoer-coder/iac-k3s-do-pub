# Provider reads the DO token ONLY from the environment (no hardcoding)
#   export DIGITALOCEAN_TOKEN=... (GitHub Actions will inject this as a secret)

provider "digitalocean" {}

# --- Remote backend (RECOMMENDED) ---
# 1) Create a Terraform Cloud org & workspace "do-k3s-prod"
# 2) Add TFC_TOKEN as a GitHub Secret (optional) and let GH Actions export it
# 3) Uncomment this block and set your org/workspace.
#
# terraform {
#   backend "remote" {
#     organization = "YOUR_TFC_ORG"
#     workspaces {
#       name = "do-k3s-prod"
#     }
#   }
# }
