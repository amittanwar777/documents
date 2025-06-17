# Deployment Strategy Using Init Container Based Approach

## Overview

This document outlines the CI/CD deployment strategy across different environments (SIT, QA, UAT, PROD) using an **init container-based approach** in OpenShift. This approach decouples artifact updates from runtime image updates, allowing greater flexibility, traceability, and reliability.

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

## Environment-wise Workflow (Detailed Explanation)

### 🔹 STE (System Test Environment)

- This is typically used by developers or automation to validate very early-stage changes.
- No changes are required in the current process.
- It directly reads from the state repo (`downloadartifacts.json`) and downloads the artifacts at runtime.
- Suitable for fast feedback loops and frequent changes.

> ✅ Benefits: Fast changes  
> ❌ Limitations: Runtime dependency on stash; not ideal for stable builds

---

### 🔹 CIT (Continuous Integration Test Environment)

- Similar to STE, this environment also uses the state repo directly.
- Developers or testers can push changes to the repo and immediately see the results.
- Pods download artifacts during runtime based on what is defined in the repo.
- Like STE, CIT is intended for speed, not for reliability or traceability.

> ✅ Benefits: Fast iteration  
> ❌ Limitations: No version control of deployed artifacts; risk of downtime if stash is unavailable

---

### 🔹 SIT / QA (System Integration Testing / Quality Assurance)

This is where we introduce the new **init container-based approach**.

1. **Commit in State Repo**  
   Developers update `downloadartifacts.json` with the desired artifacts and versions to be included in the image.

2. **Build Artifact Image**  
   A Jenkins job (e.g., `rhel_artifact_image_bc_version`) is triggered.  
   This job:
   - Reads the JSON file.
   - Packages the specified artifacts into a container image.
   - Pushes the image to an **internal non-prod image registry**.

3. **Deploy to SIT/QA**  
   Another Jenkins deployment job is triggered using the image built in step 2.  
   During deployment:
   - The **init container** (running the artifact image) starts first.
   - It unpacks the artifacts into a shared directory (`emptyDir`).
   - The **main container** (e.g., NGINX) then starts, using those pre-loaded artifacts.

4. **Test**  
   Once the pod is running, automated or manual testing is performed to ensure the image works correctly.

> ✅ Key Point: Artifact image is now fully built and traceable. We know exactly what version is deployed.

---

### 🔹 UAT (User Acceptance Testing)

In this environment, **we do not rebuild the artifact image**. We reuse the one validated in SIT/QA.

1. **Reuse Existing Image**  
   We take the same image tag that was used in SIT/QA.

2. **Deploy to UAT**  
   A Jenkins deployment job is triggered with the same image.  
   - The deployment flow is identical to SIT/QA.
   - No JSON or artifact changes should happen here.

3. **Test in UAT**  
   Business teams or QA engineers validate the application functionality in this near-prod environment.

4. **Promote If Successful**  
   If the UAT is successful, the image is **tagged for production**.  
   For example: `rhel_artifact_image_bc_version_prod`.

> ✅ Key Point: No rebuilds. We’re just moving the same tested image across stages — ensuring consistency and immutability.

---

### 🔹 PROD (Production)

1. **Deploy Using Promoted Image**  
   In production, the deployment job uses the **exact image** that passed SIT and UAT testing.

2. **Deployment Behavior**  
   - Init container unpacks the artifacts from the image.
   - Main container (NGINX or runtime base) starts using the ready artifacts.

3. **No Surprises**  
   Since we never rebuilt the image after UAT, production is now running an image that was thoroughly tested.

> ✅ Key Point: This makes the deployment repeatable, reliable, and fully auditable.

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

## Technical Recap

### Init-Based Pattern in OpenShift:

- Artifact image is used as an **init container**.
- It unpacks artifacts into a shared `emptyDir` volume.
- The main container (e.g., NGINX) uses these files at runtime.
- Decouples artifact and runtime container concerns.

---

## Notes on STE and CIT Environments

- **No changes** to current flow for STE and CIT environments.
- They continue using the state repo for faster changes and direct restarts.

---