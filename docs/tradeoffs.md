# Architecture trade-offs

## 1. EKS vs self-managed Kubernetes

**Chosen:** EKS.

Why: managed Kubernetes control plane, strong AWS integration, common enterprise skill, and enough low-level visibility to demonstrate platform engineering.

Trade-off: EKS still leaves node, add-on, networking, upgrade, cost, and workload governance decisions to the platform team. A more managed option can reduce operational burden but can also reduce control.

## 2. Managed node group vs dynamic provisioning

**Chosen:** one EKS managed node group.

Why: simplest way to show node sizing, min/max/desired capacity, AZ placement, upgrades, and scheduling without introducing another controller.

Production alternative: Karpenter or EKS Auto Mode when workload diversity and rapid right-sizing justify the extra architectural choice.

## 3. Terraform community modules vs raw resources

**Chosen:** `terraform-aws-modules/vpc/aws` and `terraform-aws-modules/eks/aws` pinned to major versions.

Why: less boilerplate and well-known patterns. The code remains readable in interviews.

Trade-off: module abstraction can hide AWS primitives. An enterprise platform should wrap upstream modules with organization standards, tests, version pinning, and an upgrade process.

## 4. GitHub Actions CI + Argo CD CD

**Chosen:** CI builds artifacts; Argo CD deploys.

Why: clean separation of concerns. CI needs ECR push permission, not cluster-admin. Argo CD detects and repairs configuration drift.

Trade-off: there is an extra Git commit between build and deployment. This is desirable for auditability but adds promotion workflow design.

## 5. Same repository for source and GitOps state

**Chosen:** monorepo for the portfolio demo.

Why: one clone, one README, easy traceability, and fewer credentials.

Production alternative: separate application-source and environment-config repositories. That allows stricter permissions, independent promotion, and cleaner separation between builders and deployers.

## 6. CI commits the image tag directly

**Chosen:** workflow updates the dev overlay after a successful image push.

Why: demonstrates a complete automated path with minimal machinery.

Trade-off: protected branches may reject bot pushes. Production environments often use a bot-created PR, promotion controller, image updater, or environment-specific repository.

## 7. Automatic Argo CD synchronization

**Chosen:** `prune: true` and `selfHeal: true`.

Why: makes drift correction visible and keeps a demo deterministic.

Production alternative: auto-sync in dev, controlled promotion/approval in stage/prod depending on change risk and compliance requirements.

## 8. Public EKS endpoint

**Chosen:** enabled for a single-engineer lab.

Why: avoids requiring a VPN or bastion just to use kubectl.

Risk: API exposure is broader. Production should restrict public endpoint CIDRs or use private-only API access through enterprise network connectivity.

## 9. One NAT gateway

**Chosen:** lower cost.

Trade-off: AZ-level NAT failure can affect workloads using private-subnet egress. Production commonly uses one NAT gateway per AZ or replaces some NAT traffic with VPC endpoints.

## 10. kube-prometheus-stack

**Chosen:** open-source Prometheus Operator + Grafana stack.

Why: fast path to meaningful Kubernetes dashboards, alerts, and ServiceMonitor-based application scraping.

Trade-off: running monitoring inside the same cluster means a severe cluster outage can also affect its monitoring. Enterprises may use a central/managed observability backend.

## 11. Trivy fail-on HIGH/CRITICAL

**Chosen:** security is a release gate.

Why: proves the software supply chain includes an objective control before publishing/deploying an image.

Trade-off: real organizations need vulnerability exception workflows, SLA by severity, base-image ownership, and suppression governance to avoid blocking delivery indefinitely.

## 12. No secrets operator in v1

**Chosen:** no application secret is required.

Why: avoids adding credentials solely to demonstrate secret handling.

Next step: External Secrets Operator with AWS Secrets Manager and pod identity/IRSA. Avoid storing application secrets in Git.

## 13. No ingress in v1

**Chosen:** ClusterIP only.

Why: avoids unnecessary public cloud cost and keeps focus on platform mechanics.

Next step for a public API: AWS Load Balancer Controller + ALB ingress + ACM + Route 53 + WAF, with separate public/private subnet paths.
