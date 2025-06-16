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

- **Scenario**: Only the base image is updated (no change to artifact image).
- **Action**: Use `oc rollout restart` or re-trigger deployment.
- **Why it works**: Since artifacts are delivered via init container and the base image runs the app, a base image change is safe and easy.
- **Impact**: No image rebuilds required; fast patching across environments.

### 2. 📦 Artifact Image Updated (Standard Flow)

- **Scenario**: A new version of the artifact is created (e.g., app binary changes).
- **Action**:
  - Rebuild and push artifact image.
  - Update `artifact-loader` image tag in deployment.
  - Trigger a rollout.
- **Note**: Base image remains unchanged unless needed.

### 3. ⚠️ Stale Artifact Image (Bad Case)

- **Scenario**: Artifact image hasn’t been rebuilt in a long time.
- **Risk**: Security CVEs, outdated dependencies in artifact image.
- **Fix**: 
  - Rebuild the artifact image on latest RHEL base.
  - Push with a new tag.
  - Update deployment accordingly.

### 4. 🔁 Edge Case (Single Image/Service Updated)

- **Scenario**: Only one image (e.g., `finv`) gets a new artifact version, others remain unchanged.
- **Action**: Follow standard update for that one deployment.
- **Consideration**: Keep version alignment and base image parity in mind.

---

## 🛠️ Build Strategy

### Artifact Image (Build-Time Image)
```Dockerfile
FROM registry.redhat.io/ubi8/ubi
COPY ./target/my-artifacts/ /app/artifacts/
```

- Contains static binaries and configuration files.
- No need for a runtime or services.

### Runtime Image (Run-Time Base)
- May use Alpine, UBI Minimal, or a hardened base.
- Should **not** contain the application artifacts itself.
- Only loads and runs from `/shared`.

---

## 🧪 Testing Strategy

- **Unit test** binaries before image creation.
- Run **integration tests** in pre-prod clusters with patched base images.
- Validate artifact loading via initContainer logs.
- Use readiness probes to ensure the main container starts only when artifacts are ready.

---

## 🔐 Security Considerations

- Ensure `initContainer` and main container have compatible UID/GID.
- Use `securityContext` if needed to allow writing to `emptyDir`.
- Enable `imagePullPolicy: Always` during testing to avoid stale image pulls.
- Watch for SELinux or PodSecurity restrictions in OpenShift.

---

## 📦 Example Versioning

| Component        | Tag/Version Example        |
|------------------|----------------------------|
| Artifact Image    | `artifact-image:rhel-20240601` |
| Runtime Image     | `runtime-image:ubi9-1.2.4`      |

Use digest pins in production for immutability and reproducibility.

---

## 🔁 Patch Workflow

1. **To Patch Base Image Only:**
   - Rebuild and push runtime image.
   - Trigger `oc rollout restart` to pull the latest image.
   - Init container remains unchanged.

2. **To Update Artifacts:**
   - Rebuild artifact image.
   - Update deployment YAML (or Helm/Kustomize).
   - Apply via GitOps or CI pipeline.

---

## 🧾 Summary Table

| Scenario                  | Update Needed           | Rebuild?         | Safe to Patch? |
|---------------------------|--------------------------|------------------|----------------|
| Only base image changes   | Runtime image            | No               | ✅ Yes         |
| New artifact version      | Artifact image           | Yes (artifact)   | ✅ Yes         |
| Artifact image outdated   | Artifact + runtime       | Yes (both)       | ⚠️ Only after rebuild |
| Single service updated    | Affected deployment only | Yes (artifact)   | ✅ Yes         |

---

## 📎 Final Notes

- This model is excellent for separating artifact ownership (developers) from runtime/image ownership (DevOps/SRE).
- Works well with GitOps and image scanning tools.
- Enables proactive CVE patching without breaking application logic.