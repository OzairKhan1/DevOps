# Production CI Pipeline

```text
Git Push
    │
    ▼
Checkout Source Code
    │
    ▼
Lint
(Flake8 / ESLint / Checkstyle)
    │
    ▼
Unit Tests
(pytest / JUnit / Jest)
    │
    ▼
Coverage Report
    │
    ▼
SonarQube Analysis
    │
    ▼
Dependency Scan
(Snyk)
    │
    ▼
GitLeaks
(Secrets Scan)
    │
    ▼
Docker Build
    │
    ▼
Hadolint
(Dockerfile Scan)
    │
    ▼
Trivy
(Container Image Scan)
    │
    ▼
Smoke Test
    │
    ▼
Cosign
(Optional Image Signing)
    │
    ▼
Push Image
(Amazon ECR / Docker Hub)
```

## Pipeline Summary

| Stage | Purpose | Common Tools |
|--------|---------|--------------|
| Checkout | Fetch source code from Git | Git, Jenkins, GitHub Actions |
| Lint | Detect code style and quality issues | Flake8, ESLint, Checkstyle |
| Unit Tests | Verify individual functions/classes | pytest, JUnit, Jest |
| Coverage Report | Measure test coverage | coverage.py, JaCoCo, Istanbul |
| SonarQube Analysis | Static code quality & security analysis | SonarQube |
| Dependency Scan | Detect vulnerable libraries | Snyk, Dependabot, OWASP Dependency-Check |
| Secrets Scan | Prevent committing API keys/passwords | GitLeaks, TruffleHog |
| Docker Build | Package the application into a container | Docker |
| Dockerfile Scan | Validate Dockerfile best practices | Hadolint |
| Image Scan | Detect vulnerabilities in container images | Trivy, Grype, Docker Scout |
| Smoke Test | Verify the container starts and basic endpoints work | curl, pytest, Postman |
| Image Signing | Cryptographically sign container images | Cosign |
| Push Image | Publish image to container registry | Amazon ECR, Docker Hub, GHCR |
