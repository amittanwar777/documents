# Deployment Strategy Using Init Container Based Approach

## Overview

This document outlines the CI/CD deployment strategy across different environments (STE, CIT, SIT/QA, UAT, PROD) using an **init container-based approach** in OpenShift. This approach decouples artifact updates from runtime image updates, allowing greater flexibility, traceability, and reliability.

---

## Current Process (Legacy)

- Developers commit to the **state repo** (`downloadartifacts.json`) with the artifacts to be deployed via NGINX.
- The state repo contains different `json` files representing **bounded contexts** (a collection of artifacts grouped logically).
- Deployment jobs use these definitions to download artifacts and serve them over NGINX.

### Issues / Drawbacks

- ❌ **Not production-grade**: Downloads artifacts at runtime from stash.
- ❌ **No versioning**: No clear tagging/version of deployed artifacts.
- ❌ **High risk**: Stash failure can cause pod restart issues and application downtime.
- ❌ **No single source of truth**: Difficult to trace what version is running in which environment.

---

## Proposed Solution: Init Container Based Approach

### Key Concepts

- **Artifact Image**: A container image (based on RHEL) containing the application binaries/artifacts.
- **Runtime Base Image**: A minimal or hardened image that actually runs the application (e.g., NGINX).
- **Init Container**: Unpacks the artifact image into a shared volume (`emptyDir`) before the main container starts.

### Benefits

- ✅ Artifact updates are **separate from runtime updates**.
- ✅ Supports **tagging and version control**.
- ✅ **Promotable across environments** (SIT → UAT → PROD).
- ✅ Resilient to runtime failures (pods don’t rely on stash at runtime).
- ✅ Better CI/CD, reproducibility, and flexibility.

---

## Environment Workflow

### STE & CIT

- Use the current approach (pull artifacts directly from the state repo).
- Fast iteration and validation.

### SIT/QA

1. **Commit**: Update `downloadartifacts.json` in state repo.
2. **Build**: Trigger Jenkins job  
   Example: `rhel_artifact_image_bc_version` → builds and pushes image to non-prod registry.
3. **Deploy**: Trigger deployment using built artifact image.
4. **Test**: Run tests to validate deployment.

### UAT

1. **Reuse**: Use the same artifact image from SIT/QA.
2. **Deploy**: Trigger deployment with the same image.
3. **Test**: Validate in UAT.
4. **Promote**: If successful, tag the artifact image for PROD  
   Example: `rhel_artifact_image_bc_version_prod`.

### PROD

1. **Deploy**: Use the promoted artifact image.
2. No rebuild or changes — ensures immutability and reproducibility.

---

## Tagging & Version Management

- A metadata file in **S3** maps image tags to their content (mirrors `downloadartifacts.json` structure).
- This allows all stakeholders to view:
  - What each image contains.
  - Which version is running in each environment.

---

## Future Enhancement

- Build a **simple UI** to visualize:
  - Image tags and contents.
  - Environment-wise deployments.
  - Artifact promotion history.

---

## 📊 Flow Diagram of the Pipeline

```mermaid
flowchart TD
    subgraph DevOps Flow

    A1[Developer Commits]
    A2[Update downloadartifacts.json]
    A3[Build Artifact Image]
    A4[Push to Non-Prod Registry]

    end

    subgraph Lower Envs
    B1[STE]
    B2[CIT]
    end

    subgraph QA Stage
    C1[SIT/QA]
    end

    subgraph Staging
    D1[UAT]
    end

    subgraph Production
    E1[PROD]
    end

    A1 --> A2 --> A3 --> A4
    A4 --> B1
    A4 --> B2
    A4 --> C1
    C1 --> D1
    D1 --> E1

    click A2 "https://your-repo-link.com/downloadartifacts.json" _blank