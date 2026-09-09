<h1 align="center">✈️ FlightOps</h1>

<p align="center">
  <strong>A cloud-native flight booking platform built with production-grade infrastructure engineering practices.</strong>
</p>

## Overview

FlightOps is a Python web application with a PostgreSQL database, deployed on **GKE Standard** with a full **GitOps** pipeline.

The project covers the **entire lifecycle**: application code → Docker → Terraform (GKE) → Kubernetes manifests → ArgoCD (GitOps) → GitHub Actions CI/CD → Prometheus observability → OPA Gatekeeper policy enforcement → Argo Rollouts progressive delivery.

The Flask backend serves a flight booking workflow where users can search flights across US states, view availability, create bookings, and manage their tickets. PostgreSQL runs as an in-cluster StatefulSet, the app is exposed via the **Kubernetes Gateway API** with Google-managed TLS certificates, and secrets are managed through **GCP Secret Manager** with Workload Identity.