# Backstage self-service layer

Backstage is the front door, not the deployment engine. Developers use the portal to discover services and invoke golden paths. The platform team owns the templates and guardrails.

```mermaid
flowchart LR
 D[Developer] --> B[Backstage]
 B --> T[Golden Path]
 T --> G[GitHub]
 G --> CI[GitHub Actions]
 CI --> ECR[Amazon ECR]
 CI --> GR[GitOps State]
 GR --> A[Argo CD]
 A --> EKS[Amazon EKS]
 EKS --> P[Prometheus]
 P --> GF[Grafana]
 B --> TF[Approved Terraform Workflow]
 TF --> AWS[AWS Resources]
```

For production, add SSO/RBAC, a PostgreSQL backend, GitHub App authentication, secret management, policy-as-code, repository protection, approvals for privileged infrastructure requests, and separate dev/stage/prod promotion.
