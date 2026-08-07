# One-page architecture

```mermaid
flowchart TB
    U[Developer] -->|PR / merge| GH[GitHub]

    subgraph CI[Continuous Integration]
      GH --> A[GitHub Actions]
      A --> UT[Unit tests]
      UT --> DB[Docker build]
      DB --> TV[Trivy scan]
      TV -->|GitHub OIDC / STS| IAM[IAM CI role]
      IAM --> ECR[Amazon ECR]
      A -->|commit immutable image tag| CFG[GitOps desired state]
    end

    subgraph AWS[AWS]
      subgraph NET[VPC]
        PUB[Public subnets\nNAT / optional LB]
        PRIV[Private subnets]
        PUB --> PRIV
        subgraph EKS[Amazon EKS]
          CP[EKS control plane]
          NODES[Managed nodes]
          CP --> NODES
          subgraph PLATFORM[Platform namespaces]
            ARGO[Argo CD]
            PROM[Prometheus]
            GRAF[Grafana]
          end
          subgraph WORKLOAD[Application namespace]
            API[Sample API x2]
            SVC[ClusterIP Service]
            API --> SVC
          end
          ARGO -->|reconcile desired state| API
          ARGO -->|reconcile| PROM
          PROM -->|ServiceMonitor scrape| API
          GRAF -->|PromQL| PROM
        end
      end
      ECR -->|pull image| NODES
    end

    CFG -->|Git pull / reconciliation| ARGO
```

## Control-plane story

There are two independent reconciliation loops:

1. **Infrastructure reconciliation:** Terraform compares AWS desired state with AWS actual state and creates/updates the VPC, IAM, ECR, and EKS resources.
2. **Application reconciliation:** Argo CD compares Git desired state with Kubernetes actual state and converges the cluster.

CI does not run `kubectl apply`. This reduces credential sprawl and preserves Git as the deployment audit trail.

## Request/data path

The sample keeps application networking intentionally internal. For a production internet-facing service, add AWS Load Balancer Controller, an ALB ingress, Route 53, ACM TLS, WAF, and a clear public/private API decision.

## Identity path

GitHub Actions uses its OIDC identity token to assume a narrowly scoped AWS IAM role. The role can push only to the project ECR repository. No persistent AWS access key is required in GitHub.

## Observability path

The application exports Prometheus metrics. A `ServiceMonitor` tells Prometheus Operator what to scrape. Grafana queries Prometheus. Kubernetes/node/control-plane signals come from the kube-prometheus-stack components.

## Failure domains

- EKS control plane is AWS managed.
- Worker nodes span multiple AZs through private subnets.
- The demo uses one NAT gateway for cost, which is a deliberate egress availability trade-off.
- Application replicas are spread by the scheduler but strict topology spread constraints can be added for stronger guarantees.
