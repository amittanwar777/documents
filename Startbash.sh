# 🚀 Artifact Delivery via Init Container in OpenShift

## 📌 Overview

This document outlines a deployment pattern in OpenShift where:

- An **artifact image** (based on RHEL) delivers application binaries.
- A **runtime base image** (possibly different, minimal, or hardened) runs the application.
- The artifact image is used as an `initContainer` and pushes files into a shared `emptyDir` volume.
- The main container uses these artifacts during runtime.

This decouples **artifact updates** from **runtime updates**, enabling simpler patching, better CI/CD workflows, and enhanced flexibility.

---

## 🧱 Architecture

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

## ⚙️ OpenShift Deployment YAML (Example)

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

- **Separation of Concerns**: Artifact delivery and runtime logic are independently managed.
- **Fast Patching**: Runtime image can be patched without rebuilding artifact logic.
- **Immutability**: Artifact image contains prebuilt content, can be version-controlled.
- **Reusable Base Images**: Common runtime base images used across teams or apps.

---

## 🛠️ Build Process

**Artifact Image (RHEL-based):**

```dockerfile
FROM registry.redhat.io/ubi8/ubi
COPY ./target/artifacts/ /app/artifacts/
```

- This image is only used to stage artifacts, no need to run a service inside it.

**Runtime Image:**

- Could be minimal UBI, Alpine, or custom hardened OS.
- Responsible only for running the application using staged artifacts.

---

## 🔄 Patching Strategy

### ✅ Easy Base Image Patching

- Since the application runs on the **runtime container**, updating the base image is simple.
- You can update the runtime base image (e.g., for CVEs) without rebuilding the artifact image.
- Example: Patch base image → redeploy via `oc rollout restart deployment/my-app`.

### ⚠️ Nuances to Watch For

| Nuance                  | Description                                                                 | Recommendation                                     |
|-------------------------|-----------------------------------------------------------------------------|---------------------------------------------------|
| Image Compatibility     | Runtime and artifact images may drift                                       | Test artifact compatibility with newer runtimes   |
| Artifact Staleness      | Old artifact images may contain outdated binaries                           | Rebuild artifacts every 3 months or as needed     |
| Init Container Failures | Errors in artifact copy can break startup                                   | Use logs, liveness/readiness probes               |
| File Permissions        | Shared files may have wrong UID/GID                                         | Match UID or run as root (if allowed by PSP/PSA)  |
| SELinux/PSA Restrictions| OpenShift security may block certain behaviors                              | Define proper `securityContext` in both containers|

---

## 🧪 Testing Strategy

- **Unit test** the artifact contents in CI/CD pipelines.
- Use a **test deployment** in OpenShift to validate runtime behavior after patching.
- Use **initContainer logs** to verify artifact delivery success.
- Add **readiness/liveness probes** to validate application availability.

---

## 🔁 CI/CD Recommendations

- Maintain separate pipelines:
  - **Artifact Build Pipeline** → builds and pushes `artifact-image:tag`.
  - **Base Runtime Image Updates** → patch and roll out `runtime-image:tag`.

- Use Helm or Kustomize to template deployment manifests.

---

## 📦 Example Versioning Strategy

- `artifact-image:rhel-20240601`
- `runtime-image:ubi9-v1.2.5`

Use digest pins in production deployments where image immutability is critical.

---

## 🧾 Summary

| Component         | Responsibility                          |
|------------------|------------------------------------------|
| Artifact Image    | Delivers application binaries            |
| Init Container    | Stages artifacts to shared volume        |
| emptyDir Volume   | Temporary, shared between containers     |
| Runtime Container | Executes app logic using shared artifacts|
| Base Image Patch  | Handled independently and easily         |

---