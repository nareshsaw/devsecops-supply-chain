# DevSecOps Secure Software Supply Chain

![CI](https://github.com/nareshsaw/devsecops-supply-chain/actions/workflows/supply-chain.yml/badge.svg)

An end-to-end, security-first CI/CD pipeline on GitHub Actions. Every change is scanned and policy-checked before it is built; every image is scanned, given an SBOM, signed, and shipped with build provenance; and a Kubernetes cluster enforces the same guardrails at admission time.

## Pipeline

```
 push / PR
    │
    ├─▶ 1. Secret scan ............ gitleaks (full git history)
    ├─▶ 2. Tests + SAST + deps .... pytest · Bandit · pip-audit
    ├─▶ 3. Policy-as-code ......... OPA/Rego (conftest) on K8s + Dockerfile · Kyverno CLI tests
    │
    ├─▶ 4. Build → Scan → SBOM → Sign → Provenance → Verify      (main branch only)
    │        Docker Buildx → GHCR · Grype · Syft (SPDX) · cosign keyless · SLSA provenance · cosign verify
    │
    └─▶ 5. Admission control ...... kind + Kyverno ValidatingPolicy: compliant deploy admitted, insecure deploy blocked
```

## Security controls

| Control | Tool | Fails the build when |
|---|---|---|
| Secret scanning | gitleaks | a credential is found anywhere in git history |
| SAST | Bandit | medium+ severity Python issue |
| Dependency scanning | pip-audit | a pinned dependency has a known vulnerability |
| Container image scanning | Grype (results in the GitHub Security tab) | a fixable critical vulnerability exists |
| SBOM | Syft (SPDX JSON) | — (stored as a build artifact and as a signed attestation) |
| Image signing | cosign keyless (Sigstore, GitHub OIDC; no long-lived keys) | the signature cannot be verified |
| Build provenance | GitHub artifact attestations (SLSA) | — |
| Dependency pinning | exact versions in `requirements.txt` + Dependabot | — |
| Policy-as-code (CI) | OPA/Rego via conftest | manifest uses `:latest`, runs privileged/as root, lacks limits; Dockerfile has no non-root `USER` or uses remote `ADD` |
| Admission control (cluster) | Kyverno `ValidatingPolicy` (CEL) | the API server rejects non-compliant workloads |

## Repository layout

```
app/                    Flask service + pinned requirements
tests/                  unit tests
Dockerfile              non-root, pinned base image
k8s/                    deployment.yaml (compliant), bad-deployment.yaml (must be rejected)
policy/conftest/        OPA/Rego rules for Kubernetes manifests and the Dockerfile
policy/kyverno/         Kyverno ValidatingPolicies + CLI test suite
.github/workflows/      the pipeline
.github/dependabot.yml  automated updates for pip, Docker and GitHub Actions
```

## Run the checks locally

```bash
pip install -r requirements-dev.txt
pytest -q
bandit -r app -ll
pip-audit -r app/requirements.txt

conftest test k8s/deployment.yaml -p policy/conftest --namespace main
conftest test k8s/bad-deployment.yaml -p policy/conftest --namespace main   # expect failures
conftest test Dockerfile -p policy/conftest --namespace dockerfile
kyverno test policy/kyverno/tests
gitleaks dir .
```

## Verify a published image yourself

```bash
cosign verify ghcr.io/nareshsaw/devsecops-supply-chain:1.0.0 \
  --certificate-identity-regexp "^https://github.com/nareshsaw/devsecops-supply-chain/.github/workflows/" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

gh attestation verify oci://ghcr.io/nareshsaw/devsecops-supply-chain:1.0.0 --owner nareshsaw
```

## Design notes

- **Shift left, then enforce.** The same rules run in CI (fast feedback to developers) and in the cluster (a hard gate nobody can bypass).
- **Keyless signing.** cosign uses the workflow's short-lived OIDC identity, so there are no signing keys to store or rotate.
- **Least-privilege workflow.** Default `contents: read`; only the build job gets `packages`, `id-token`, `attestations` and `security-events` write access.
- **Next steps:** pin third-party actions to commit SHAs, add a Kyverno `ImageValidatingPolicy` to admit only signed images, and add CodeQL.

## Results

<!-- Paste screenshots or output from your own runs: green pipeline, Grype findings, the blocked deployment message -->

## What I learned

<!-- 3–5 points in your own words, e.g. a check that failed and how you fixed it -->
