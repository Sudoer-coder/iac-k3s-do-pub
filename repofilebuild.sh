
# Create directories
mkdir -p env
mkdir -p .github/workflows

# Create Terraform files
touch main.tf variables.tf outputs.tf provider.tf versions.tf backend.tf 

# Create env vars file
touch env/terraform.tfvars

# Create git + workflow files
touch .gitignore .github/workflows/terraform.yml


