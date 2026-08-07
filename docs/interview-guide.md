# Interview guide: questions this project can answer

## “Design an internal developer platform.”

Start with the developer journey, not Kubernetes:

> A developer merges code. CI validates the change, produces an immutable artifact, and updates desired state. The platform reconciles that desired state into a standardized runtime with security and observability built in.

Then map the journey to GitHub Actions, ECR, Argo CD, EKS, and Prometheus/Grafana.

## “Why GitOps?”

- Git is the desired-state audit trail.
- Argo CD continuously detects drift.
- CI does not need cluster-admin credentials.
- Rollback is a Git revert.
- The same promotion model can be extended across environments.

## “How would you secure CI/CD?”

Discuss:

- OIDC federation and short-lived credentials
- least-privilege ECR IAM policy
- protected branches and reviews
- dependency/container/IaC scanning
- immutable image tags
- image signing and SBOM as next steps
- environment approvals for production

## “What happens when a deployment fails?”

1. GitHub Actions failing before manifest update means no deployment begins.
2. Argo CD shows desired-vs-live differences and sync health.
3. Kubernetes readiness blocks bad pods from receiving traffic.
4. Deployment rollout status/events identify scheduling, image-pull, probe, or resource failures.
5. Prometheus/Grafana show error rate, latency, restarts, saturation, and resource pressure.
6. Recovery can be a Git revert to the previous image SHA.

## “How do you troubleshoot a pod stuck Pending?”

Check events and scheduler reasons, then capacity, requests, taints/tolerations, affinity, node selectors, PVC binding, quotas, and autoscaling. In this project, resource requests are explicit so you can discuss how unschedulable pods relate to node capacity.

## “How would you make EKS highly available?”

- Control plane: EKS manages multi-AZ control-plane availability.
- Data plane: private subnets and node capacity across AZs.
- Workloads: >=2 replicas, topology spread/anti-affinity, PDB, probes.
- Egress: NAT gateway per AZ or architecture using VPC endpoints.
- Stateful services: managed multi-AZ data stores rather than local cluster storage where practical.

## “How would you make this multi-tenant?”

Add namespace-per-team/application boundaries, ResourceQuota, LimitRange, NetworkPolicy, RBAC groups, admission policy, workload identity, standardized Helm/Kustomize templates, and platform APIs/golden paths. Use dedicated clusters/accounts when isolation requirements exceed namespace boundaries.

## “How would you scale this to 100 teams?”

- platform templates instead of hand-created YAML
- reusable Terraform modules and account vending
- Backstage/portal self-service
- ApplicationSet for Argo CD fleet patterns
- policy-as-code
- centralized observability
- Karpenter/Auto Mode for workload-aware capacity
- SLOs for the platform itself
- platform product metrics: lead time, deployment success, onboarding time, adoption, support load

## “Why not deploy directly from GitHub Actions?”

Direct deployment is simpler initially, but CI would need Kubernetes credentials and become responsible for both artifact creation and environment convergence. Argo CD gives continuous reconciliation, drift detection, self-healing, and a pull-based security model.

## “How do you manage rollback?”

The image is tagged with a Git commit SHA and the deployed SHA is committed to Git. Revert the GitOps commit and Argo CD reconciles the previous version. For progressive delivery, add Argo Rollouts and automated metric analysis.

## “How would you handle secrets?”

Do not store plaintext secrets in Git. Add AWS Secrets Manager + External Secrets Operator, or another enterprise secret manager. Bind workload identity to the minimum secret paths required by each service.

## “What is missing before production?”

Say this explicitly; it shows architectural judgment:

- remote Terraform state and state locking
- account/environment separation
- private EKS API/network path
- ingress/TLS/WAF/DNS
- external secrets
- network policy
- policy-as-code
- image signing/SBOM/provenance
- centralized logs/traces
- backup/DR strategy
- SLOs/alerts/on-call runbooks
- controlled promotion between environments
- cost dashboards and rightsizing
