<p align="center">
  <img src="docs/assets/flightops-banner.png" alt="FlightOps Banner" width="100%" />
</p>

<h1 align="center">✈️ FlightOps</h1>

<p align="center">
  <strong>A cloud-native flight booking platform built with production-grade infrastructure engineering practices.</strong>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/GCP-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="GCP" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm" /></a>
  <a href="#"><img src="https://img.shields.io/badge/ArgoCD-EF5B25?style=for-the-badge&logo=argo&logoColor=white" alt="ArgoCD" /></a>
  <a href="#"><img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white" alt="GitHub Actions" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white" alt="Flask" /></a>
  <a href="#"><img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" /></a>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/github/license/ChetanThapliyal/FlightOps?style=flat-square&color=blue" alt="License" /></a>
  <a href="#"><img src="https://img.shields.io/badge/IaC-Terraform-blueviolet?style=flat-square" alt="IaC" /></a>
  <a href="#"><img src="https://img.shields.io/badge/k8s-GKE_Standard-blue?style=flat-square&logo=kubernetes&logoColor=white" alt="Kubernetes" /></a>
</p>

---

## Overview

FlightOps is a Python web application with a PostgreSQL database, deployed on **GKE Standard** with a full **GitOps** pipeline.

The project covers the **entire lifecycle**: application code → Docker → Terraform (GKE) → Kubernetes manifests → ArgoCD (GitOps) → GitHub Actions CI/CD → Prometheus observability → OPA Gatekeeper policy enforcement → Argo Rollouts progressive delivery.

The Flask backend serves a flight booking workflow where users can search flights across US states, view availability, create bookings, and manage their tickets. PostgreSQL runs as an in-cluster StatefulSet, the app is exposed via the **Kubernetes Gateway API** with Google-managed TLS certificates, and secrets are managed through **GCP Secret Manager** with Workload Identity.

---

## Architecture

```mermaid

graph TB
    subgraph CI_CD ["CI/CD Pipeline"]
        GHA["GitHub Actions"]
    end

    subgraph Registry ["Artifact Registry"]
        AR["Docker Images"]
    end

    subgraph GitOps ["GitOps"]
        ARGO["ArgoCD"]
    end

    subgraph GCP ["GCP: GKE Standard"]
        subgraph K8S ["Kubernetes Cluster"]
            subgraph Gateway ["Gateway Layer"]
                GW["Gateway API + GCP ALB"]
                GCERT["Google Certificate Manager"]
            end
            subgraph AppLayer ["Application Layer"]
                ROLLOUT["Flask Argo Rollout"]
                SVC["Flask Service"]
            end
            subgraph DataLayer ["Data Layer"]
                PGSVC["PostgreSQL Service"]
                PGSS["PostgreSQL StatefulSet"]
            end
            subgraph Platform ["Platform"]
                PROM["Prometheus + Grafana"]
                OPA["OPA Gatekeeper"]
                SM["Secret Manager CSI"]
            end
        end
    end

    subgraph IaC ["Infrastructure as Code"]
        TF["Terraform<br/>(VPC · GKE · IAM · DNS · Secrets)"]
    end

    GHA -->|"build · push"| AR
    GHA -->|"update image tag"| ARGO
    ARGO -->|"deploys"| ROLLOUT
    GW <-->|"managed TLS"| GCERT
    GW -->|"routes traffic"| SVC
    SVC --> ROLLOUT
    ROLLOUT -->|"queries"| PGSVC
    PGSVC --> PGSS
    TF -->|"provisions"| K8S
    SM -->|"injects secrets"| ROLLOUT
    SM -->|"injects secrets"| PGSS
    PROM -->|"scrapes metrics"| ROLLOUT

    style CI_CD fill:#1a1a2e,stroke:#2088FF,color:#e0e0e0
    style Registry fill:#1a1a2e,stroke:#2496ED,color:#e0e0e0
    style GitOps fill:#1a1a2e,stroke:#EF5B25,color:#e0e0e0
    style GCP fill:#0d1117,stroke:#4285F4,color:#e0e0e0
    style K8S fill:#111827,stroke:#326CE5,color:#e0e0e0
    style Gateway fill:#161b22,stroke:#4285F4,color:#e0e0e0
    style AppLayer fill:#161b22,stroke:#3776AB,color:#e0e0e0
    style DataLayer fill:#161b22,stroke:#4169E1,color:#e0e0e0
    style Platform fill:#161b22,stroke:#E6522C,color:#e0e0e0
    style IaC fill:#1a1a2e,stroke:#7B42BC,color:#e0e0e0
    style GHA fill:#161b22,stroke:#2088FF,color:#58a6ff
    style AR fill:#161b22,stroke:#2496ED,color:#58a6ff
    style ARGO fill:#161b22,stroke:#EF5B25,color:#58a6ff
    style GW fill:#161b22,stroke:#4285F4,color:#58a6ff
    style GCERT fill:#161b22,stroke:#4285F4,color:#58a6ff
    style ROLLOUT fill:#161b22,stroke:#3776AB,color:#58a6ff
    style SVC fill:#161b22,stroke:#3776AB,color:#58a6ff
    style PGSVC fill:#161b22,stroke:#4169E1,color:#58a6ff
    style PGSS fill:#161b22,stroke:#4169E1,color:#58a6ff
    style TF fill:#161b22,stroke:#7B42BC,color:#58a6ff
    style PROM fill:#161b22,stroke:#E6522C,color:#58a6ff
    style OPA fill:#161b22,stroke:#E6522C,color:#58a6ff
    style SM fill:#161b22,stroke:#E6522C,color:#58a6ff

```

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Application** | Python, Flask |
| **Database** | PostgreSQL (in-cluster StatefulSet) |
| **DB Admin** | `psql` CLI |
| **Networking** | Kubernetes Gateway API (GKE Gateway Controller) |
| **TLS** | Google Certificate Manager (managed certs) |
| **Containerization** | Docker |
| **Orchestration** | GKE Standard (Kubernetes) |
| **GitOps** | ArgoCD (App of Apps) |
| **Package Management** | Helm |
| **Progressive Delivery** | Argo Rollouts (canary) |
| **Infrastructure as Code** | Terraform (modular) |
| **Cloud Provider** | Google Cloud Platform (GKE) |
| **CI/CD** | GitHub Actions + Workload Identity Federation |
| **Secrets** | GCP Secret Manager + CSI Driver |
| **Observability** | Prometheus + Grafana |
| **Policy** | OPA Gatekeeper |
| **Logging** | GCP Cloud Logging |

---

## Database Schema

The PostgreSQL database contains four tables that model the flight booking domain:

```mermaid

erDiagram
    STATES {
        int id PK
        varchar state_code "2-char code (e.g. CA)"
        varchar state_name
    }

    FLIGHTS {
        int id PK
        int departure_state_id FK
        int arrival_state_id FK
        timestamptz departure_time
        timestamptz arrival_time
        decimal price
    }

    USERS {
        int id PK
        varchar name
        varchar password
        varchar email
    }

    TICKETS {
        int id PK
        varchar ticket_number "unique booking reference"
        int departure_state_id FK
        int arrival_state_id FK
        timestamptz departure_time
        timestamptz arrival_time
        decimal ticket_price
        int user_id FK
    }

    STATES ||--o{ FLIGHTS : "departure_state_id"
    STATES ||--o{ FLIGHTS : "arrival_state_id"
    STATES ||--o{ TICKETS : "departure_state_id"
    STATES ||--o{ TICKETS : "arrival_state_id"
    USERS ||--o{ TICKETS : "user_id"

```

---

## Key Features

- **End-to-end IaC**: Every piece of infrastructure (VPC, GKE cluster, IAM, DNS, Secret Manager) is provisioned via modular Terraform. Zero manual console steps.
- **GKE Standard on GCP**: Managed Kubernetes with Workload Identity, Gateway API, and auto-scaling node pools.
- **GitOps with ArgoCD**: App of Apps pattern, Git is the single source of truth. ArgoCD auto-syncs and self-heals.
- **Gateway API + managed TLS**: Kubernetes Gateway API with GKE-native Gateway Controller and Google-managed certificates.
- **GCP Secret Manager**: Secrets injected via CSI Driver with Workload Identity — never stored in etcd or Git.
- **Full observability**: Prometheus + Grafana dashboards for cluster, app, and database metrics.
- **Policy enforcement**: OPA Gatekeeper enforces security policies (no privileged containers, required labels, trusted image repos).
- **Progressive delivery**: Argo Rollouts with canary deployments — gradual traffic shifting with automated rollback.
- **In-cluster PostgreSQL**: Database runs as a Kubernetes StatefulSet with persistent volumes; administration via `psql` CLI.
- **Flight booking workflow**: Search flights across US states, view availability, book tickets, and manage user accounts.

---