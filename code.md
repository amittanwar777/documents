# 🚀 Artifact Delivery via Init Container in OpenShift

## 📌 Overview

This document outlines a deployment pattern in OpenShift where:

- An **artifact image** (based on RHEL) delivers application binaries.
- A **runtime base image** (possibly different, minimal, or hardened) runs the application.
- The artifact image is used as an `initContainer` and pushes files into a shared `emptyDir` volume.
- The main container uses these artifacts during runtime.

This decouples **artifact updates** from **runtime updates**, enabling simpler patching, better CI/CD workflows, and enhanced flexibility.

---

## 🧱 Architecture Diagram

```
+--------------------+
| Init Container     | <-- Artifact image (RHEL-based)
|--------------------|
| Copies artifacts → |
| /shared (emptyDir) |
+--------------------+
           ↓
+--------------------+
| Main Container     | <-- Runtime image (e.g., UBI, Alpine)
|--------------------|
| Reads from /shared |
| Runs the app       |
+--------------------+
```

---

## ⚙️ Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      volumes:
        - name: shared-artifacts
          emptyDir: {}

      initContainers:
        - name: artifact-loader
          image: myregistry/artifact-image:rhel-latest
          command: ["/bin/sh", "-c"]
          args:
            - cp -r /app/artifacts/* /shared/
          volumeMounts:
            - name: shared-artifacts
              mountPath: /shared

      containers:
        - name: app-runtime
          image: myregistry/runtime-image:base-latest
          command: ["/bin/sh", "-c"]
          args:
            - ./start-app.sh /shared
          volumeMounts:
            - name: shared-artifacts
              mountPath: /shared
```

---

## ✅ Benefits

- **Decoupled Images**: You can update base image or artifacts independently.
- **Security Patching**: The runtime (base) image is patchable without rebuilding artifacts.
- **CI/CD Friendly**: Artifact delivery is static and version-controlled.
- **Multi-Stage Flexibility**: Runtime and build stages are totally separated.

---

## 🔄 Base Image Evergreening — Operational Scenarios

### 1. ✅ Happiest Case (Only Base Image Updated)

- Scenario: Only the base image is updated (no change to artifact image).
- Action: Use `oc rollout restart` or re-trigger deployment.
- Impact: No image rebuilds required; fast patching across environments.

### 2. 📦 Artifact Image Updated (Standard Flow)

- Scenario: A new version of the artifact is created.
- Action:
  - Rebuild and push artifact image.
  - Update `artifact-loader` image tag in deployment.
  - Trigger a rollout.

### 3. ⚠️ Stale Artifact Image (Bad Case)

- Scenario: Artifact image hasn’t been rebuilt in a long time.
- Risk: CVEs, outdated dependencies.
- Fix: Rebuild the artifact image on latest RHEL base, redeploy.

### 4. 🔁 Edge Case (Single Service Updated)

- Scenario: Only one deployment (e.g., `finv`) gets a new artifact version.
- Action: Treat like a standard update for that deployment only.

---

## 🛠️ Build Strategy

### Artifact Image

```dockerfile
FROM registry.redhat.io/ubi8/ubi
COPY ./target/my-artifacts/ /app/artifacts/
```

### Runtime Image

- Minimal, hardened base (e.g., UBI, Alpine).
- Runs the app using files in `/shared`.

---

## 🧪 Testing Strategy

- Unit test binaries before image creation.
- Run integration tests in test clusters.
- Validate artifact copy via init container logs.
- Use readiness probes in main container.

---

## 🔐 Security Considerations

| Concern              | Recommendation                              |
|----------------------|----------------------------------------------|
| UID/GID mismatch     | Align UID or use securityContext             |
| Init failure         | Add logs and readiness checks                |
| SELinux/PSA          | Review OpenShift pod security policies       |
| Stale image pulls    | Use `imagePullPolicy: Always` in test        |

---

## 📦 Versioning Strategy

| Component        | Example Tag               |
|------------------|---------------------------|
| Artifact Image    | artifact-image:rhel-20240601 |
| Runtime Image     | runtime-image:ubi9-1.2.4     |

---

## 🔁 Patch Workflow

1. **To Patch Base Image Only**
   - Rebuild runtime image → Push
   - Trigger rollout: `oc rollout restart deployment/my-app`

2. **To Update Artifacts**
   - Rebuild artifact image → Push
   - Update init container reference → Deploy

---

## 🧾 Summary Table

| Scenario                  | Update Needed     | Rebuild?         | Safe to Patch? |
|---------------------------|-------------------|------------------|----------------|
| Only base image changes   | Runtime image      | No               | ✅ Yes         |
| New artifact version      | Artifact image     | Yes (artifact)   | ✅ Yes         |
| Artifact image outdated   | Artifact + runtime | Yes (both)       | ⚠️ After rebuild |
| Single service updated    | Deployment only    | Yes (artifact)   | ✅ Yes         |