locals {
  # A simple label used in names
  label = "${var.project_name}-${var.droplet_name}"
}

data "digitalocean_ssh_key" "this" {
  name = var.ssh_key_name
}

# Cloud-init: harden OS, install K3s, configure firewall, prepare kubeconfig
data "cloudinit_config" "k3s" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<-CLOUDCFG
      #cloud-config
      package_update: true
      package_upgrade: true
      packages:
        - ufw
        - fail2ban
        - unattended-upgrades
      ssh_deletekeys: false
      disable_root: true
      ssh_pwauth: false

      write_files:
        - path: /usr/local/bin/bootstrap.sh
          permissions: '0755'
          content: |
            #!/usr/bin/env bash
            set -euxo pipefail

            # Ensure admin user exists and inherits DO injected SSH key
            if ! id -u ${var.user_name} >/dev/null 2>&1; then
              adduser --disabled-password --gecos "" ${var.user_name}
              usermod -aG sudo ${var.user_name}
            fi

            install -d -m 700 -o ${var.user_name} -g ${var.user_name} /home/${var.user_name}/.ssh
            if [ -f /root/.ssh/authorized_keys ]; then
              cp /root/.ssh/authorized_keys /home/${var.user_name}/.ssh/authorized_keys
              chown ${var.user_name}:${var.user_name} /home/${var.user_name}/.ssh/authorized_keys
              chmod 600 /home/${var.user_name}/.ssh/authorized_keys
            fi

            # SSH hardening
            sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            systemctl restart ssh || systemctl restart sshd || true

            # UFW baseline
            ufw --force reset
            ufw default deny incoming
            ufw default allow outgoing
            # HTTP/HTTPS for ingress
            ufw allow 80/tcp
            ufw allow 443/tcp
            # Admin access (SSH + API) only from allowed CIDRs
            %{for cidr in var.admin_cidrs~}
            ufw allow from ${cidr} to any port 22 proto tcp
            ufw allow from ${cidr} to any port 6443 proto tcp
            %{endfor~}
            ufw --force enable

            # unattended-upgrades already installed -> ensure enabled
            dpkg-reconfigure -f noninteractive unattended-upgrades || true

            # Install K3s
            export INSTALL_K3S_CHANNEL="${var.k3s_channel}"
            export K3S_KUBECONFIG_MODE="600"
            K3S_EXEC_OPTS=""
            %{if var.k3s_disable_traefik}
            K3S_EXEC_OPTS="--disable traefik"
            %{endif}

            curl -sfL https://get.k3s.io | sh -s - ${var.k3s_disable_traefik ? "--disable traefik" : ""}

            # Wait for kubeconfig and replace 127.0.0.1 with public IP
            IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address || hostname -I | awk '{print $1}')
            for i in {1..30}; do
              test -f /etc/rancher/k3s/k3s.yaml && break
              sleep 3
            done
            install -d -m 700 -o ${var.user_name} -g ${var.user_name} /home/${var.user_name}/.kube
            cp /etc/rancher/k3s/k3s.yaml /home/${var.user_name}/.kube/config
            sed -i "s/127.0.0.1/$IPV4/g" /home/${var.user_name}/.kube/config
            chown -R ${var.user_name}:${var.user_name} /home/${var.user_name}/.kube

            # Basic fail2ban enable
            systemctl enable --now fail2ban || true

      runcmd:
        - [ bash, -lc, "/usr/local/bin/bootstrap.sh" ]
    CLOUDCFG
  }
}

resource "digitalocean_droplet" "k3s" {
  name       = var.droplet_name
  region     = var.region
  size       = var.droplet_size
  image      = "ubuntu-24-04-x64"
  ipv6       = true
  monitoring = true
  backups    = false

  ssh_keys = [
    data.digitalocean_ssh_key.this.id
  ]

  tags      = var.tags
  user_data = data.cloudinit_config.k3s.rendered
}

# Lock down network with a DO firewall (in addition to UFW on the VM)
resource "digitalocean_firewall" "k3s" {
  name        = "${local.label}-fw"
  droplet_ids = [digitalocean_droplet.k3s.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # SSH from admin CIDRs only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.admin_cidrs
  }

  # K8s API from admin CIDRs only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "6443"
    source_addresses = var.admin_cidrs
  }

  # Egress allow all
  outbound_rule {
    protocol              = "tcp"
    port_range            = "0"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "0"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Lookup existing project by name
data "digitalocean_project" "selected" {
  name = var.project_name
}

resource "digitalocean_project_resources" "attachments" {
  project = data.digitalocean_project.selected.id
  resources = [
    digitalocean_droplet.k3s.urn,
  ]
}
