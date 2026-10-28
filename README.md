# monitoring-infra: Grafana + VictoriaMetrics on AWS

A highly available monitoring system on AWS. It is built with **Terraform** (using modules),
configured with **Ansible** (using a dynamic inventory), and run by a **Jenkins** pipeline.

The diagram is in [`docs/architecture.png`](docs/architecture.png).

---

## 1. Folder structure

```
monitoring-infra/
├── jenkins/
│   └── Jenkinsfile                  pipeline: Dependencies > Init > Validate > Fmt > Plan > Apply > Ansible / Destroy
│
├── terraform/                       BUILDS the AWS infrastructure
│   ├── main.tf                      joins the 4 modules together
│   ├── provider.tf                  AWS, Mumbai, tags on every resource
│   ├── variables.tf                 inputs
│   ├── terraform.tfvars             YOUR values (change 2 lines)
│   ├── outputs.tf                   prints the Grafana link
│   └── modules/
│       ├── vpc/                     VPC, 4 subnets, IGW, NAT, route tables, NACLs
│       ├── security-groups/         alb-sg, bastion-sg, monitoring-sg
│       ├── ec2/                     bastion host, monitoring-a, monitoring-b
│       └── alb/                     load balancer + target group (Grafana :3000)
│           (each module has main.tf, variables.tf, outputs.tf)
│
├── ansible/                         INSTALLS the software
│   ├── ansible.cfg                  settings (uses the dynamic inventory)
│   ├── requirements.yml             amazon.aws collection
│   ├── inventory/aws_ec2.yml        DYNAMIC INVENTORY: finds the servers in AWS by tag
│   ├── group_vars/all.yml           versions, password, key path
│   ├── group_vars/monitoring.yml    log in through the bastion host
│   ├── site.yml                     main playbook
│   └── roles/
│       ├── node_exporter/           :9100  CPU / memory / disk
│       ├── victoriametrics/         :8428  stores the numbers
│       ├── vmagent/                 collects from both servers
│       └── grafana/                 :3000  dashboards
│
└── docs/architecture.png
```

## 2. Which file builds which part of the diagram

| Diagram | File |
|---|---|
| VPC, subnets 10.0.1/2/11/12, IGW, NAT, Public/Private RT, NACLs | `terraform/modules/vpc/` |
| alb-sg, bastion-sg, monitoring-sg | `terraform/modules/security-groups/` |
| Bastion host, EC2 monitoring-a, EC2 monitoring-b | `terraform/modules/ec2/` |
| ALB, Target group Grafana :3000 | `terraform/modules/alb/` |
| node_exporter, vmagent, VictoriaMetrics, Grafana | `ansible/roles/` |
| "each vmagent scrapes both servers" | `ansible/roles/vmagent/templates/scrape.yml.j2` |
| Jenkins → Terraform → Ansible | `jenkins/Jenkinsfile` |

---

## 3. The Jenkins pipeline stages

| # | Stage | What it does |
|---|---|---|
| 1 | **Dependencies** | Checks Terraform and Ansible; installs the `amazon.aws` collection and `boto3` (needed by the dynamic inventory) |
| 2 | **Terraform Init** | Downloads the AWS provider and loads the modules |
| 3 | **Terraform Validate** | Checks the code has no errors |
| 4 | **Terraform Fmt** | Checks the code is neatly formatted |
| 5 | **Terraform Plan** | Shows what will be created (or deleted, for `destroy`) |
| 6 | **Terraform Apply** | Creates the AWS infrastructure *(apply only)* |
| 7 | **Ansible: Configure Servers** | Shows the servers found by the dynamic inventory, then installs the software *(apply only)* |
| 8 | **Terraform Destroy** | Deletes everything *(destroy only)* |

- `ACTION = apply`: stages 1 → 2 → 3 → 4 → 5 → 6 → 7
- `ACTION = destroy`: stages 1 → 2 → 3 → 4 → 5 → 8

## 4. What is the dynamic inventory?

A normal inventory is a file with IP addresses written by hand.
A **dynamic inventory** asks AWS every time: *"which servers exist right now?"*

1. Terraform tags every resource `Project = monitoring-infra`, and each server with
   `Role = monitoring` or `Role = bastion` (`terraform/modules/ec2/main.tf`).
2. `ansible/inventory/aws_ec2.yml` asks AWS for running servers with that Project tag
   and makes groups from the Role tag.
3. `site.yml` runs on the `monitoring` group. The bastion's IP for the SSH jump also
   comes from AWS (`group_vars/monitoring.yml`).

No IP addresses are written anywhere. Try it: `cd ansible && ansible-inventory --graph`

```
@all:
  |--@bastion:
  |  |--bastion-host
  |--@monitoring:
  |  |--monitoring-a
  |  |--monitoring-b
```

---

## 5. Setup

### On your laptop (once)

1. EC2 console (Mumbai) → **Key pairs** → create one and download the `.pem`.
2. Edit **`terraform/terraform.tfvars`**:
   - `my_ip`: run `curl ifconfig.me` and add `/32`
   - `key_name`: your key pair's name
3. Push this folder to GitHub.

### In Jenkins

1. The Jenkins machine needs **Terraform**, **Ansible** and **Python 3** installed.
2. **Manage Jenkins → Credentials → Global → Add Credentials**:

   | ID | Kind | Value |
   |---|---|---|
   | `aws-access-key-id` | Secret text | your AWS access key |
   | `aws-secret-access-key` | Secret text | your AWS secret key |
   | `ec2-ssh-key` | SSH Username with private key | username `ubuntu`, paste the whole `.pem` |

3. Open your pipeline job → **Configure** → Pipeline → *Pipeline script from SCM* → your repo →
   **Script Path: `jenkins/Jenkinsfile`** ← important, the Jenkinsfile moved into the `jenkins/` folder
4. **Build with Parameters → apply**. It takes about 8–10 minutes.
5. The end of the log shows: `Grafana is ready: http://monitoring-infra-alb-xxxx.ap-south-1.elb.amazonaws.com`

### Run without Jenkins (optional)

```bash
cd terraform
terraform init && terraform validate && terraform fmt -check -recursive
terraform plan -out=tfplan && terraform apply tfplan

cd ../ansible
ansible-galaxy collection install -r requirements.yml
pip3 install boto3 botocore
ansible-inventory --graph
ansible-playbook site.yml -e ssh_key_file=~/.ssh/my-key.pem

# delete everything
cd ../terraform && terraform destroy
```

## 6. Check it works

1. Open the Grafana link and log in: user `admin`, password `Admin@123` (in `ansible/group_vars/all.yml`).
2. **Explore** → choose **VictoriaMetrics** → type `node_load1` → **Run query**. You'll see 2 lines, one per server.
3. **Show high availability:** stop `monitoring-a` in the EC2 console, wait a minute, refresh Grafana. It still works.

**After the demo: Build with Parameters → destroy.** The NAT Gateway and the ALB cost money every hour.

---

## 7. Explain it to your teacher

- **Terraform** builds the AWS infrastructure. It is split into **modules** (vpc → security-groups → ec2 → alb), like LEGO blocks. Each module passes its IDs to the next one.
- **Ansible** installs the software. A **dynamic inventory** finds the servers by their AWS tags, so no IPs are hard-coded.
- **Jenkins** runs it all: it checks the code (validate, fmt), shows the plan, builds the infrastructure, then configures the servers.
- **Monitoring flow on each server:** node_exporter measures → vmagent collects (from **both** servers) → VictoriaMetrics stores → Grafana shows.
- **High availability:** 2 identical servers in 2 AZs, each with the full data. The ALB only sends users to healthy servers.
- **Security:**
  - The servers are in private subnets with no public IP.
  - SSH works only through the bastion, and only from your IP.
  - Grafana can only be reached through the ALB.

## 8. Common problems

| Stage / error | Fix |
|---|---|
| Dependencies: `ansible: command not found` | Install Ansible on the Jenkins machine (Mac: `brew install ansible`) |
| Fmt fails | Run `terraform fmt -recursive` in `terraform/` and push |
| Plan: `InvalidKeyPair.NotFound` | `key_name` must match a key pair in **ap-south-1** |
| Ansible: `failed to parse aws_ec2.yml` / `boto3 required` | The Dependencies stage installs it. Check that its log shows "boto3 already installed" |
| Ansible: `groups['bastion']` is undefined | The bastion isn't running yet, or the tags changed. Check `ansible-inventory --graph` |
| Ansible: `Permission denied (publickey)` | Check the `ec2-ssh-key` credential: username `ubuntu`, the full `.pem` pasted |
| Ansible can't reach the bastion | Your public IP changed. Update `my_ip` in tfvars, push, run apply again |
| Grafana link shows 502 / 503 | Grafana is still starting. Wait 1–2 minutes |

*Kept simple on purpose:* NACLs are open (security groups do the filtering), there is one NAT Gateway,
Terraform state is kept in the Jenkins workspace (real projects use S3), and Grafana uses plain HTTP.
