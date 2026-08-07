Yes. For better understanding, you should test this repo in **two modes**:

**Local learning mode** = understand each layer cheaply on your laptop.
**Organization mode** = change the repo so it matches enterprise standards, security, networking, governance, and team scale.

Your current repo already separates the responsibilities properly: Terraform provisions infrastructure, GitHub Actions handles CI, Argo CD handles deployment, Prometheus/Grafana handle observability, and Backstage is the developer-facing self-service layer.

## 1. How to test locally without creating EKS first

Do not start with AWS. First prove the application, Kubernetes manifests, GitOps concepts, monitoring, and Backstage locally.

Use this local architecture:

```text
Laptop
  |
  +--> Docker
  |
  +--> kind/minikube
  |      |
  |      +--> Argo CD
  |      +--> Sample Service
  |      +--> Prometheus
  |      +--> Grafana
  |
  +--> Backstage
  |
  +--> Local Git clone
```

For Windows, I recommend:

```text
Docker Desktop
WSL2 Ubuntu
kind
kubectl
helm
Terraform
AWS CLI
Node.js
Git
VS Code
```

### Step 1 — run only the application

Go to:

```powershell
cd app
```

Build:

```powershell
docker build -t idp-sample-service:local .
```

Check:

```powershell
docker images
```

Run:

```powershell
docker run -d `
  --name idp-sample `
  -p 8080:8080 `
  idp-sample-service:local
```

Then test:

```powershell
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

At this point you understand:

```text
Code
 ↓
Dockerfile
 ↓
Container Image
 ↓
Container
 ↓
Application
```

Do this **before Kubernetes**.

---

# 2. Run Kubernetes locally using kind

Install kind.

Then:

```powershell
kind create cluster --name idp-local
```

Verify:

```powershell
kubectl cluster-info
kubectl get nodes
```

Expected:

```text
NAME                      STATUS   ROLE
idp-local-control-plane   Ready    control-plane
```

Now load your local image:

```powershell
kind load docker-image idp-sample-service:local --name idp-local
```

For local testing, temporarily change your deployment image from ECR to:

```yaml
image: idp-sample-service:local
imagePullPolicy: IfNotPresent
```

Then deploy:

```powershell
kubectl apply -f app\k8s\
```

Check:

```powershell
kubectl get pods
kubectl get deployment
kubectl get svc
```

This lets you learn Kubernetes **without paying for EKS**.

---

# 3. Test Argo CD locally

Install Argo CD into kind:

```powershell
kubectl create namespace argocd

kubectl apply -n argocd -f `
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check:

```powershell
kubectl get pods -n argocd
```

Then expose UI:

```powershell
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Open:

```text
https://localhost:8081
```

Now you can understand the key flow:

```text
GitHub
   |
   v
Argo CD
   |
Compare
   |
Git desired state
vs
Kubernetes actual state
   |
   v
Sync
```

Your repo uses an **app-of-apps** bootstrap model so that after the initial bootstrap, Argo CD manages the child applications from Git.

---

# 4. Test Prometheus and Grafana locally

Once Argo CD deploys monitoring:

```powershell
kubectl get pods -A
```

Look for:

```text
prometheus
grafana
kube-state-metrics
node-exporter
```

Grafana:

```powershell
kubectl port-forward `
  svc/kube-prometheus-stack-grafana `
  3001:80 `
  -n monitoring
```

Open:

```text
http://localhost:3001
```

Prometheus:

```powershell
kubectl port-forward `
  svc/kube-prometheus-stack-prometheus `
  9090:9090 `
  -n monitoring
```

Open:

```text
http://localhost:9090
```

Then check application metrics.

This gives you the understanding:

```text
Application
   |
/metrics
   |
ServiceMonitor
   |
Prometheus
   |
PromQL
   |
Grafana
```

---

# 5. Run Backstage locally

Backstage is easiest to understand locally.

Create a generated Backstage application once:

```powershell
npx @backstage/create-app@latest
```

Example name:

```text
idp-portal
```

Then:

```powershell
cd idp-portal
yarn dev
```

Open:

```text
http://localhost:3000
```

Merge the configuration from:

```text
backstage/app-config.platform.yaml
```

Your current README already describes Backstage as a separate application with its own Node.js runtime rather than something you simply `kubectl apply`.

The important local test is:

```text
Backstage
   |
   +--> Catalog
   |
   +--> sample-service
   |
   +--> Create
           |
           v
      Golden Path
```

You should be able to explain:

> “Backstage does not provision Kubernetes directly. It provides the self-service interface. The underlying automation is executed through GitHub, Terraform and GitOps.”

---

# 6. Terraform: learn locally without creating AWS resources

You can still validate Terraform locally.

Go to:

```powershell
cd terraform\envs\dev
```

Run:

```powershell
terraform fmt -recursive
terraform init
terraform validate
```

Then:

```powershell
terraform plan
```

Do **not** immediately run:

```powershell
terraform apply
```

`plan` lets you understand:

```text
Terraform code
     |
     v
Dependency graph
     |
     v
AWS provider
     |
     v
Proposed resources
```

Read the plan carefully.

Look for:

```text
VPC
Subnets
Route Tables
NAT Gateway
Security Groups
EKS
Node Groups
IAM Roles
OIDC
ECR
```

This is much more useful for learning than blindly applying.

---

# 7. What changes when an organization uses this repo

This is the most important part.

Your current repo is a **reference implementation**, not something I would copy unchanged into a large enterprise.

Think of it as:

```text
Reference Architecture
        |
        v
Organization Standards
        |
        v
Production Platform
```

The changes normally happen in these areas:

| Area            | Portfolio repo          | Organization                      |
| --------------- | ----------------------- | --------------------------------- |
| AWS accounts    | One account             | Dev/Test/Stage/Prod accounts      |
| Terraform state | Simple remote state     | Central encrypted state + RBAC    |
| VPC             | Project VPC             | Corporate landing-zone networking |
| EKS endpoint    | Public/private possible | Usually private                   |
| Authentication  | Personal/admin access   | SSO + IAM Identity Center         |
| CI              | GitHub Actions          | Org-approved runners/workflows    |
| Secrets         | Basic integration       | Vault / Secrets Manager           |
| GitOps          | Single repo             | Controlled environment repos      |
| Argo CD         | One installation        | HA + RBAC + SSO                   |
| Backstage       | Basic portal            | SSO + RBAC + plugins + DB         |
| Monitoring      | Local Prometheus        | Central observability platform    |
| Security        | Trivy                   | SAST/SCA/container/IaC/runtime    |
| Policies        | Limited                 | OPA/Kyverno/Gatekeeper            |
| Cost            | Basic                   | FinOps tags, quotas, budgets      |
| DR              | Minimal                 | RTO/RPO defined                   |
| Governance      | Basic                   | approvals and policy-as-code      |

---

# 8. First thing to change: account structure

Portfolio:

```text
AWS Account
 |
 +-- VPC
 +-- EKS
 +-- ECR
```

Enterprise:

```text
AWS Organization
       |
       +-- Security Account
       |
       +-- Shared Services
       |
       +-- Networking
       |
       +-- Development
       |
       +-- Testing
       |
       +-- Production
```

Terraform should not hard-code one account.

You want something like:

```text
terraform/
├── modules/
│   ├── network/
│   ├── eks/
│   ├── ecr/
│   ├── iam/
│   └── observability/
│
└── environments/
    ├── dev/
    ├── test/
    ├── stage/
    └── prod/
```

---

# 9. Change the networking model

Your learning environment can be:

```text
Internet
 |
NAT
 |
Private Subnet
 |
EKS
```

In an organization:

```text
Corporate Network
       |
Direct Connect / VPN
       |
Transit Gateway
       |
Central Firewall
       |
Hub VPC
       |
Spoke VPC
       |
Private EKS
```

You may need:

```text
Private API endpoint
VPC endpoints
Route53 private zones
AWS Network Firewall
Transit Gateway
Direct Connect
Corporate DNS
Proxy
```

Interview answer:

> “I wouldn't independently create networking inside every platform environment if the organization already has a landing zone. My EKS module would consume network outputs from the central networking platform.”

Very important architect-level thinking.

---

# 10. Change identity and access

Don't give developers:

```text
cluster-admin
```

Use:

```text
SSO
 |
AWS IAM Identity Center
 |
IAM Roles
 |
EKS Access Entries
 |
Kubernetes RBAC
```

Then map:

```text
Platform Admin
Developer
SRE
Security
Read Only
```

For example:

```text
Developer
   |
namespace team-a
   |
Can:
  get
  list
  watch
  logs

Cannot:
  delete namespace
  create clusterrole
  modify system resources
```

---

# 11. Change Backstage for organization use

Local Backstage:

```text
Backstage
 |
GitHub
 |
Kubernetes
```

Enterprise Backstage:

```text
                    Backstage
                        |
        +---------------+----------------+
        |               |                |
        v               v                v
      SSO             Catalog         TechDocs
        |
        +--> GitHub
        +--> Argo CD
        +--> Kubernetes
        +--> Terraform
        +--> ServiceNow
        +--> Vault
        +--> Grafana
        +--> PagerDuty
        +--> Cost platform
```

Most importantly:

**Do not give Backstage broad admin credentials.**

Use workflow delegation:

```text
Developer
   |
Backstage
   |
Request
   |
Workflow
   |
Approval/Policy
   |
Terraform
```

Instead of:

```text
Backstage
   |
Administrator credentials
   |
AWS
```

---

# 12. Enterprise golden path

This is where this project becomes a true platform.

Developer opens Backstage:

```text
Create Service
```

Select:

```text
Language
Python

Service name
payment-api

Owner
payments-team

Environment
dev

Database
PostgreSQL

Exposure
Internal

Observability
Standard
```

Platform generates:

```text
GitHub repository
Dockerfile
CI workflow
Kubernetes deployment
Service
Ingress
ServiceMonitor
Dashboard
Alerts
Terraform configuration
Argo CD Application
catalog-info.yaml
Documentation
```

So:

```text
Developer
   |
   v
Backstage
   |
Golden Path
   |
   +--> GitHub
   +--> CI
   +--> Terraform
   +--> GitOps
   +--> Monitoring
   +--> Documentation
```

This is the central idea of platform engineering.

---

# 13. Add governance

Your organization version should eventually include:

```text
Kyverno / Gatekeeper
```

Example policies:

```text
No :latest image
Containers must run non-root
CPU/memory limits required
Approved registries only
Mandatory labels
No privileged containers
NetworkPolicy required
Secrets cannot appear in manifests
```

Flow:

```text
Developer PR
    |
    v
CI
    |
    +--> Unit Test
    +--> SAST
    +--> Dependency Scan
    +--> Docker Scan
    +--> IaC Scan
    +--> Policy Check
             |
             v
           Merge
             |
             v
           Argo CD
```

---

# 14. Organization CI/CD changes

Your portfolio CI is roughly:

```text
Build
Test
Scan
Push
Update Git
```

Enterprise:

```text
Code
 |
PR
 |
 +--> Unit Tests
 +--> Code Quality
 +--> SAST
 +--> SCA
 +--> Secret Scan
 +--> IaC Scan
 |
Build
 |
SBOM
 |
Sign Image
 |
Container Scan
 |
ECR
 |
GitOps PR
 |
Approval
 |
Argo CD
 |
Dev
 |
Integration Test
 |
Stage
 |
Approval
 |
Production
```

Tools could be:

```text
SonarQube
Trivy
Snyk
Checkov
Cosign
Syft
GitHub Advanced Security
OPA
```

---

# 15. Observability changes

Your current platform already uses Prometheus/Grafana.

Locally:

```text
Prometheus -> Grafana
```

Organization:

```text
Applications
   |
OpenTelemetry
   |
   +--> Metrics
   |      -> Prometheus/Mimir
   |
   +--> Logs
   |      -> Loki/Splunk
   |
   +--> Traces
          -> Tempo/Jaeger

           |
           v
        Grafana
```

Add:

```text
SLO
SLI
Error Budget
Alerts
On-call
DORA metrics
```

---

# 16. Secrets

Never put:

```yaml
password: abc123
```

or GitHub secrets into manifests.

Use:

```text
AWS Secrets Manager
        |
External Secrets Operator
        |
        v
Kubernetes Secret
        |
        v
Application
```

Or:

```text
HashiCorp Vault
```

---

# 17. How I recommend you learn this repo

Do not try everything on day one.

Use this progression:

```text
LEVEL 1
Application locally
↓
Docker

LEVEL 2
kind
↓
Kubernetes

LEVEL 3
Argo CD
↓
GitOps

LEVEL 4
Prometheus/Grafana
↓
Observability

LEVEL 5
Backstage
↓
Self-service

LEVEL 6
Terraform plan
↓
Infrastructure design

LEVEL 7
AWS EKS
↓
Real cloud deployment

LEVEL 8
Security + IAM + networking
↓
Enterprise platform

LEVEL 9
Multi-environment
↓
Dev/Test/Stage/Prod

LEVEL 10
Golden paths + governance + SRE
↓
Platform Architect
```

That is the best way to use this repository for interview preparation too: **first make every component work independently, then connect them, then explain what must change for enterprise production**.

Your current README already documents several of those production gaps—for example private EKS access, long-term monitoring, policy controls, multi-environment separation, and stronger Backstage automation—so the repo is already structured as a learning/reference implementation rather than pretending the lab design is production-ready.

If you want, the next thing I would do is turn this into a **Day 1 → Day 10 hands-on lab**, where every day you execute commands, verify output, intentionally break something, troubleshoot it, and answer the corresponding Platform Architect interview questions.
=====================================================================================

Continue with a **10-Day Internal Developer Platform Hands-On Lab**. The goal is not just to make the project run. By Day 10, you should be able to explain the architecture, troubleshoot it, defend the trade-offs, and describe what changes for an enterprise organization.

| Day | Focus                               | What you must prove                |
| --- | ----------------------------------- | ---------------------------------- |
| 1   | Application + Docker                | Service runs locally               |
| 2   | Local Kubernetes                    | Service runs on kind               |
| 3   | Kubernetes troubleshooting          | You can diagnose failures          |
| 4   | Argo CD                             | Git becomes source of truth        |
| 5   | Prometheus + Grafana                | Metrics and dashboards work        |
| 6   | Backstage                           | Developer self-service works       |
| 7   | Terraform                           | Understand every AWS resource      |
| 8   | Real EKS                            | Deploy platform on AWS             |
| 9   | Security + enterprise controls      | IAM, policies, secrets, networking |
| 10  | Production architecture + interview | Present full solution confidently  |

# Day 1 — Application and Docker

Start here because Kubernetes problems are much easier to understand after you know the application itself works.

From your repository root:

```powershell
cd app
```

Check the files:

```powershell
Get-ChildItem
```

You should understand the purpose of:

```text
app/
├── src/
├── tests/
├── Dockerfile
├── requirements.txt
└── k8s/
```

First run the application without Docker.

If it is Python:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Run tests:

```powershell
pytest
```

Then start the application according to the application entry point.

Test:

```powershell
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

Then build Docker:

```powershell
docker build -t idp-sample-service:v1 .
```

Verify:

```powershell
docker images
```

Run:

```powershell
docker run -d `
  --name idp-sample `
  -p 8080:8080 `
  idp-sample-service:v1
```

Check:

```powershell
docker ps
docker logs idp-sample
```

Test:

```powershell
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

Now intentionally break it.

Change the container port or application port so they don't match.

For example:

```text
Application listens: 8080
Docker/Kubernetes expects: 8000
```

Then troubleshoot:

```powershell
docker logs idp-sample
docker inspect idp-sample
```

The interview lesson from Day 1 is:

> “Before troubleshooting Kubernetes, I validate the application independently. I confirm dependency installation, tests, container build, process startup, listening port, health endpoint, and metrics endpoint. This isolates application problems from platform problems.”

# Day 2 — Kubernetes locally with kind

Install Docker Desktop, `kubectl`, and `kind`.

Confirm:

```powershell
docker version
kubectl version --client
kind version
```

Create the cluster:

```powershell
kind create cluster --name idp-local
```

Verify:

```powershell
kubectl cluster-info
kubectl get nodes -o wide
```

Now load your local image into kind:

```powershell
kind load docker-image idp-sample-service:v1 --name idp-local
```

Check Kubernetes YAML.

Understand these resources:

| Resource       | Purpose                                  |
| -------------- | ---------------------------------------- |
| Deployment     | Runs application pods                    |
| ReplicaSet     | Maintains replicas                       |
| Pod            | Actual workload                          |
| Service        | Stable network endpoint                  |
| ServiceMonitor | Tells Prometheus what to scrape          |
| ConfigMap      | Non-sensitive configuration              |
| Secret         | Sensitive application values             |
| PDB            | Protects availability during disruptions |

For local testing use:

```yaml
image: idp-sample-service:v1
imagePullPolicy: IfNotPresent
```

Deploy:

```powershell
kubectl apply -f app\k8s\
```

Verify:

```powershell
kubectl get deployments
kubectl get pods -o wide
kubectl get svc
```

Describe the pod:

```powershell
kubectl describe pod <pod-name>
```

Check logs:

```powershell
kubectl logs <pod-name>
```

Forward the service:

```powershell
kubectl port-forward svc/sample-service 8080:80
```

Test:

```powershell
curl http://localhost:8080/health
```

Now understand this flow:

```text
Deployment
    |
    v
ReplicaSet
    |
    v
Pods
    |
    v
Service
    |
    v
Application
```

Interview explanation:

> “Deployment manages desired replica state. ReplicaSet ensures the requested number of pods exists. Service provides stable discovery independent of changing pod IPs.”

# Day 3 — Kubernetes troubleshooting

This day is extremely important for Platform Engineer interviews.

Create intentional failures.

### ImagePullBackOff

Change:

```yaml
image: invalid-image:v99
```

Apply:

```powershell
kubectl apply -f app\k8s\
```

Check:

```powershell
kubectl get pods
```

You'll likely see:

```text
ImagePullBackOff
```

Diagnose:

```powershell
kubectl describe pod <pod>
```

What you're looking for:

```text
Events
Failed to pull image
```

### CrashLoopBackOff

Change the Docker command to something invalid.

Then:

```powershell
kubectl get pods
kubectl logs <pod>
kubectl logs <pod> --previous
```

### Readiness probe failure

Change:

```yaml
path: /ready-broken
```

Check:

```powershell
kubectl describe pod <pod>
kubectl get endpoints
```

Important concept:

```text
Pod Running
does NOT mean
Application Ready
```

### CPU or memory problem

Lower memory aggressively:

```yaml
limits:
  memory: 20Mi
```

Then inspect:

```powershell
kubectl describe pod <pod>
```

Look for:

```text
OOMKilled
```

Your troubleshooting sequence should become automatic:

```text
kubectl get
       |
       v
kubectl describe
       |
       v
kubectl logs
       |
       v
kubectl get events
       |
       v
Check Service
       |
       v
Check Endpoint
       |
       v
Check Network/DNS
```

A good interview answer is:

> “I first identify whether the issue is scheduling, image retrieval, container startup, readiness, service discovery, ingress, network policy, resource pressure, or application behavior. I use `get`, `describe`, logs, previous logs, events, endpoints and node state in that order.”

# Day 4 — Argo CD and GitOps

Now move from manual Kubernetes to GitOps.

Install Argo CD:

```powershell
kubectl create namespace argocd
```

Then:

```powershell
kubectl apply -n argocd -f `
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check:

```powershell
kubectl get pods -n argocd
```

Wait until everything is running.

Port-forward:

```powershell
kubectl port-forward svc/argocd-server `
  -n argocd `
  8081:443
```

Open:

```text
https://localhost:8081
```

Get initial admin password:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret `
  -o jsonpath="{.data.password}"
```

Decode PowerShell:

```powershell
$password = kubectl -n argocd get secret argocd-initial-admin-secret `
  -o jsonpath="{.data.password}"

[System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String($password)
)
```

Bootstrap:

```powershell
kubectl apply -f argocd\bootstrap\root-app.yaml
```

Check:

```powershell
kubectl get applications -n argocd
```

Now perform the most important GitOps experiment.

Manually change the cluster:

```powershell
kubectl scale deployment sample-service --replicas=5
```

Check:

```powershell
kubectl get deployment
```

If Argo CD self-heal is enabled, Git says perhaps `2`, so Argo CD changes it back.

This demonstrates:

```text
Git
 |
 | desired replicas = 2
 |
 v
Argo CD
 |
 v
Cluster
 |
actual replicas = 5
 |
Argo CD detects drift
 |
v
replicas = 2
```

This is one of your best interview demonstrations.

# Day 5 — Prometheus and Grafana

Verify monitoring:

```powershell
kubectl get pods -n monitoring
```

Check ServiceMonitor:

```powershell
kubectl get servicemonitor -A
```

Prometheus:

```powershell
kubectl port-forward `
  svc/kube-prometheus-stack-prometheus `
  9090:9090 `
  -n monitoring
```

Open:

```text
http://localhost:9090
```

Try:

```promql
up
```

Then:

```promql
rate(http_requests_total[5m])
```

Generate traffic:

```powershell
1..100 | ForEach-Object {
    curl http://localhost:8080/
}
```

Run the PromQL query again.

Now Grafana:

```powershell
kubectl port-forward `
  svc/kube-prometheus-stack-grafana `
  3001:80 `
  -n monitoring
```

Open:

```text
http://localhost:3001
```

Understand the observability chain:

```text
Application
   |
   v
/metrics
   |
   v
ServiceMonitor
   |
   v
Prometheus
   |
   v
PromQL
   |
   v
Grafana
```

Enterprise evolution:

```text
Application
   |
OpenTelemetry
   |
   +--> Metrics
   +--> Logs
   +--> Traces
   |
Central Observability
```

# Day 6 — Backstage

Now you're ready for the IDP part.

Install Node.js LTS.

Confirm:

```powershell
node --version
npm --version
```

Generate Backstage:

```powershell
npx @backstage/create-app@latest
```

Name:

```text
idp-portal
```

Then:

```powershell
cd idp-portal
yarn dev
```

Open:

```text
http://localhost:3000
```

Now integrate the configuration in your repo's Backstage directory.

Your learning objective isn't just getting the UI running.

Understand these concepts:

| Backstage capability | Platform purpose             |
| -------------------- | ---------------------------- |
| Catalog              | Find services                |
| Software Template    | Create standardized services |
| TechDocs             | Documentation-as-code        |
| Kubernetes plugin    | Workload visibility          |
| GitHub integration   | Repo/CI information          |
| Ownership            | Team accountability          |
| Golden path          | Standard developer workflow  |

Your golden path should conceptually perform:

```text
Developer clicks:
Create Microservice
        |
        v
Backstage form
        |
        +--> Name
        +--> Owner
        +--> Description
        +--> Repository
        |
        v
Template
        |
        +--> App code
        +--> Dockerfile
        +--> CI workflow
        +--> Kubernetes YAML
        +--> catalog-info.yaml
        |
        v
GitHub repository
```

Interview explanation:

> “Backstage is not my provisioning engine. It is the developer experience layer. It provides catalog, ownership, documentation, golden paths, and self-service. Actual infrastructure operations are delegated to governed Terraform or workflow automation.”

# Day 7 — Terraform deeply

Now study Terraform.

Start:

```powershell
cd terraform\envs\dev
```

Run:

```powershell
terraform fmt -recursive
terraform init
terraform validate
```

Then:

```powershell
terraform plan
```

Do not apply immediately.

Read every planned resource.

Build your mental model:

```text
Terraform
   |
   +--> VPC
   |
   +--> Public Subnets
   |
   +--> Private Subnets
   |
   +--> Route Tables
   |
   +--> NAT Gateway
   |
   +--> Security Groups
   |
   +--> EKS
   |
   +--> Managed Node Group
   |
   +--> IAM
   |
   +--> ECR
```

You should be able to answer:

**Why private subnets?**

Worker nodes don't normally need direct inbound Internet exposure.

**Why NAT?**

Private workloads may still need outbound access.

**Why multiple AZs?**

Failure-domain resilience.

**Why managed node groups?**

AWS manages much of node lifecycle integration.

**Why Terraform module?**

Consistency and reuse.

### Terraform failure exercise

Change a variable to an invalid value.

Run:

```powershell
terraform validate
terraform plan
```

Then understand:

```text
Syntax validation
       ≠
Provider validation
       ≠
Runtime deployment success
```

# Day 8 — AWS EKS

Only now spend money on AWS.

First:

```powershell
aws sts get-caller-identity
```

You must know exactly which account you're using.

Check region:

```powershell
aws configure get region
```

Set:

```powershell
$env:AWS_REGION="ap-south-1"
```

Plan again:

```powershell
terraform plan -out=tfplan
```

Review carefully.

Then:

```powershell
terraform apply tfplan
```

This may take some time.

After completion:

```powershell
aws eks update-kubeconfig `
  --region ap-south-1 `
  --name idp-dev-eks
```

Check:

```powershell
kubectl get nodes
```

Now repeat your local workflow on real AWS.

The architecture is:

```text
Developer
   |
GitHub
   |
GitHub Actions
   |
   +--> Test
   +--> Build
   +--> Trivy
   |
   v
Amazon ECR
   |
   v
GitOps Repo
   |
   v
Argo CD
   |
   v
Amazon EKS
```

Important: destroy when you're done learning:

```powershell
terraform destroy
```

Especially because NAT Gateway and EKS cost money.

# Day 9 — Enterprise security

Now transform your thinking from:

```text
"Can I deploy?"
```

to:

```text
"Should this deployment be allowed?"
```

Add design thinking for:

```text
Identity
Secrets
Network
Supply chain
Policies
Audit
Runtime
```

The enterprise flow becomes:

```text
Developer
   |
   v
SSO
   |
   v
Backstage
   |
   v
Golden Path
   |
   v
GitHub PR
   |
   +--> Unit Test
   +--> SAST
   +--> SCA
   +--> Secret Scan
   +--> IaC Scan
   +--> Container Scan
   +--> Policy Validation
   |
   v
Image
   |
   +--> SBOM
   +--> Signature
   |
   v
ECR
   |
   v
Argo CD
   |
   v
Admission Policy
   |
   v
EKS
```

For Kubernetes, learn these controls:

```text
RBAC
NetworkPolicy
Pod Security
Kyverno/Gatekeeper
ResourceQuota
LimitRange
Service Accounts
Workload Identity
Secrets
Image policy
```

One architecture principle you should be able to state clearly:

> “Developers receive self-service capabilities, not unrestricted infrastructure privileges.”

# Day 10 — Organization-grade architecture

Now take the project from one cluster to an enterprise platform.

Instead of:

```text
One GitHub Repo
     |
One AWS Account
     |
One EKS
```

Design:

```text
                    AWS ORGANIZATION
                           |
      +--------------------+--------------------+
      |                    |                    |
 Networking            Security            Workloads
 Account               Account               Accounts
                                              |
                              +---------------+---------------+
                              |               |               |
                             Dev             Stage           Prod
                              |               |               |
                             EKS             EKS             EKS
```

Above that:

```text
                    Backstage
                        |
         +--------------+--------------+
         |              |              |
      Catalog       Golden Paths    TechDocs
         |
         v
      GitHub
         |
    GitHub Actions
         |
   Build/Test/Security
         |
       ECR
         |
      GitOps
         |
      Argo CD
         |
 +-------+-------+-------+
 |               |       |
Dev             Stage   Prod
```

And observability:

```text
Dev EKS ----\
Stage EKS ----> Central Observability
Prod EKS ---/        |
                     +--> Metrics
                     +--> Logs
                     +--> Traces
                     +--> Alerts
                     +--> SLO
```

# Your final Platform Architect story

After completing all ten days, you should be able to say:

> “I built an Internal Developer Platform with Backstage as the developer experience layer. Terraform provisions the AWS infrastructure and EKS foundation. Developers use golden paths instead of dealing directly with Kubernetes or Terraform. GitHub Actions performs tests, builds, vulnerability scanning and artifact publication using federated AWS authentication. Argo CD handles deployment through GitOps and continuously reconciles cluster state against Git. Prometheus and Grafana provide workload and platform observability. For an enterprise implementation, I would introduce multi-account isolation, private networking, SSO and RBAC, external secrets management, policy-as-code, supply-chain signing, centralized observability, environment promotion controls, HA Backstage and Argo CD, DR requirements, FinOps controls and SLO-driven operations.”

That one explanation can naturally lead into Terraform, AWS, EKS, Kubernetes, GitHub Actions, GitOps, Argo CD, Backstage, security, networking, observability, SRE, FinOps, DR, developer experience and platform governance.

### The most important learning rule

Don't just run commands successfully.

For every component, always practice:

```text
Install it
    ↓
Verify it
    ↓
Understand it
    ↓
Break it
    ↓
Troubleshoot it
    ↓
Fix it
    ↓
Explain the trade-off
    ↓
Explain how production differs
```

That is the difference between remembering interview answers and being able to handle architecture scenarios independently.
