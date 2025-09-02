<h1 align="center">🚀 K3s on DigitalOcean with Terraform + GitHub Actions + Terraform Cloud</h1>
<!-- Project Banner -->
<p align="center">
  <img src="docu/K3s IAC.png" alt="K3s on DigitalOcean with Terraform" width="800"/>
</p>

---

## 🌐 DigitalOcean Kubernetes vs. K3s on Droplet

| Feature | DigitalOcean Managed Kubernetes (DOKS) | K3s on DigitalOcean Droplet |
|---------|----------------------------------------|------------------------------|
| **Setup** | Fully managed, one-click cluster | Manual setup with Terraform + cloud-init |
| **Maintenance** | DO handles upgrades, HA, scaling | You manage upgrades, scaling, HA |
| **Cost** | Pay per node + control plane | Only Droplet + bandwidth costs |
| **Flexibility** | Standard Kubernetes (upstream) | Lightweight Kubernetes (edge-friendly) |
| **Use Cases** | Production, HA workloads, enterprise apps | Dev/test, learning, edge/IoT, lightweight apps |

👉 **Recommendation:**  
- Use **DOKS** for production, multi-node, and mission-critical workloads.  
- Use **K3s on Droplet** for cost-saving dev clusters, POCs, and lightweight apps.  

---

## 📂 Repository Structure

o-k8s/
├── main.tf # Terraform resources (Droplet, cloud-init for K3s, firewall, project)
├── variables.tf # Input variables
├── outputs.tf # Outputs (Droplet IP, kubeconfig)
├── provider.tf # DigitalOcean provider configuration
├── versions.tf # Terraform version requirements
├── backend.tf # Terraform Cloud remote backend configuration
├── env/
│ └── terraform.tfvars # Local environment variables (DO token, SSH key name, admin CIDRs)
├── .gitignore
└── .github/
└── workflows/
└── terraform.yml # GitHub Actions workflow for CI/CD


---

## ⚙️ Workflow Overview

1. **Local Development**  
   - Write/update Terraform configs in `do-k8s/`.
   - Push changes to GitHub (`git push origin main`).

2. **CI/CD with GitHub Actions**  
   - Runs `terraform fmt`, `terraform validate`, and `terraform plan`.
   - Comment plan output on PR for team review.

3. **Terraform Cloud Remote State**  
   - Stores state securely.  
   - Apply requires **manual approval** → safe for production.  

4. **Deployment**  
   - Once approved, Terraform Cloud applies changes.  
   - K3s installed via cloud-init on DigitalOcean Droplet.  
   - `kubeconfig` output ready for `kubectl`.

---

## 🔑 Why Not Auto-Deploy in GitHub Actions for Production?

⚠️ **Auto-apply is risky**:  
- Mistakes in code = Immediate infra destruction.  
- No approval step = accidental downtime.  
- Best practice = `validate + plan` in CI, `apply` only via Terraform Cloud with human approval.  

---

## 🛠️ Prerequisites

- DigitalOcean Account + API Token  
- Terraform CLI ≥ 1.5  
- Terraform Cloud account & workspace  
- GitHub repo with Actions enabled  
- SSH key added to DigitalOcean  

---

## 📦 Setup & Deployment

### 1. Clone Repo

```bash
git clone https://github.com/<your-username>/do-k8s.git
cd do-k8s

2. Configure Environment Variables

Edit env/terraform.tfvars:

do_token      = "<YOUR_DO_TOKEN>"
ssh_key_name  = "<YOUR_DO_SSH_KEY_NAME>"
admin_cidrs   = ["<YOUR_IP_CIDR>"]

3. Initialize Terraform (local test)
terraform init
terraform fmt
terraform validate

4. Run Plan Locally (optional)
terraform plan -var-file=env/terraform.tfvars

5. Push to GitHub
git status
git add .
git commit -m "Deploy K3s cluster"
git push origin main

6. Approve & Apply from Terraform Cloud

Go to Terraform Cloud Workspace.

Review plan.

Click Confirm & Apply.

🌟 Outputs

After apply:

terraform output


droplet_ip → Public IP of your K3s node

kubeconfig → Kubeconfig file to connect with kubectl

🤝 Contributing

PRs welcome! Please open issues for bug reports or suggestions.

📘 Notes

For production Kubernetes, prefer DigitalOcean Managed Kubernetes (DOKS).

For learning or edge workloads, K3s on Droplet is lightweight and cheaper.

This repo demonstrates Infra as Code + CI/CD best practices with Terraform Cloud approval workflow.

