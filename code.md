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