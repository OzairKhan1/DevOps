# Jenkins Tools Reference — Plugin vs Tools Section vs System Config vs VM Install

Legend:
- **Plugin** — Jenkins plugin required (integration/DSL steps)
- **Tools Section** — Has an entry under Manage Jenkins → Tools (name→path/version, sometimes auto-install)
- **System Config** — Needs global config under Manage Jenkins → System / Clouds (server URL, credentials, cluster info)
- **VM Install** — Actual binary/daemon must exist on the controller/agent

| Tool | Category | Plugin | Tools Section | System Config | VM Install | Notes |
|---|---|---|---|---|---|---|
| **Docker** | Build/Container | Yes (Docker, Docker Pipeline) | Yes (auto-install available) | Optional (registry creds) | Yes (Docker Engine/daemon) | Plugin gives `docker.build()` DSL; daemon still needs host-level setup (socket, cgroups) |
| **Docker Compose** | Container | Optional | No | No | Yes | Usually just called via `sh 'docker compose ...'` |
| **Kubernetes** | Orchestration | Yes (Kubernetes plugin) | No | Yes (Clouds → cluster URL, kubeconfig/creds) | Only if pipeline itself calls `kubectl` | Plugin mainly provisions dynamic Jenkins agent pods, not a CLI wrapper |
| **kubectl** | CLI | No dedicated plugin usually | No | No | Yes | Just a binary on PATH, called via `sh` |
| **Helm** | K8s packaging | Optional community plugin | Rare | No | Yes | Almost always just installed as CLI |
| **SonarQube** | Code quality/SAST | Yes (SonarQube Scanner plugin) | Yes (Scanner auto-install) | Yes (Server URL + token under System) | Auto-installed via plugin or manual | Three-part setup: plugin + tool entry + system server config |
| **Trivy** | Vulnerability/Image scan | No official plugin (mostly) | No | No | Yes | Called via `sh 'trivy image ...'`; treat like a CLI utility |
| **Snyk** | SCA/Vulnerability | Yes (Snyk Security plugin) | Yes (auto-install) | Yes (API token) | Optional (auto-installed) | |
| **OWASP Dependency-Check** | SCA | Yes | Yes (auto-install) | No | Optional | |
| **Checkmarx / Fortify** | SAST (enterprise) | Yes | Sometimes | Yes (server URL, creds) | Sometimes | Varies by vendor plugin maturity |
| **Maven** | Java build | Yes (Maven Integration) | Yes (auto-install) | No | Optional (auto-installed) | |
| **Gradle** | Java/Kotlin build | Yes (Gradle plugin) | Yes (auto-install) | No | Optional (auto-installed) | |
| **JDK** | Java runtime | Built-in | Yes (auto-install) | No | Optional (auto-installed) | |
| **JUnit** | Java testing | Yes (JUnit plugin, for report parsing) | No | No | N/A (library, not CLI) | Runs via Maven/Gradle; plugin just parses XML test reports |
| **JaCoCo** | Java coverage | Yes | No | No | N/A (library) | Reports parsed by plugin |
| **Checkstyle / PMD / SpotBugs** | Java static analysis (bugs/smells) | Yes (each has a plugin) | No (run via build tool) | No | N/A (Maven/Gradle plugin, not Jenkins tool) | Runs as part of `mvn checkstyle:check` etc.; Jenkins plugin just visualizes results |
| **Python (interpreter)** | Runtime | No official "Python plugin" widely used | No | No | Yes | Usually just installed on VM (pyenv/apt/conda) |
| **pytest** | Python testing | No dedicated plugin (uses JUnit plugin to parse `--junitxml` output) | No | No | Yes (`pip install pytest`) | Run via `sh 'pytest --junitxml=report.xml'`, then JUnit plugin parses results |
| **flake8 / pylint** | Python lint (bugs/smells) | No | No | No | Yes (`pip install`) | Just CLI tools, output can feed Warnings NG plugin |
| **Black / isort** | Python formatting | No | No | No | Yes | CLI only |
| **Bandit** | Python SAST | No dedicated plugin | No | No | Yes (`pip install bandit`) | CLI only |
| **coverage.py** | Python coverage | Cobertura plugin can visualize | No | No | Yes | Run via CLI, report parsed by plugin |
| **Warnings NG** | Aggregator for lint/static analysis results | Yes | No | No | N/A | Parses output from Checkstyle, PMD, flake8, Bandit, etc. into unified Jenkins UI |
| **Git** | SCM | Yes (Git plugin) | Yes (rare, mostly auto-detected) | Yes (credentials) | Yes (git binary) | Almost always pre-installed on agents |
| **Ansible** | Config mgmt/deploy | Yes (Ansible plugin) | Yes (auto-detect path) | No | Yes | |
| **Terraform** | IaC | Yes (community plugin, optional) | Yes (if plugin used) | No | Yes | Many teams skip the plugin entirely and just call `terraform` via `sh` |
| **AWS CLI / AWS creds** | Cloud | Yes (Pipeline: AWS Steps) | No | Yes (Credentials store) | Yes (aws cli binary) | |
| **Slack / Email** | Notification | Yes | No | Yes (webhook/SMTP server config) | No | |

## Quick mental model for any new tool

Ask these 4 questions in order:
1. **Does a Jenkins plugin exist for it?** → If no, it's just a CLI tool you call with `sh`/`bat`.
2. **Does that plugin implement a "Tool Installation" (auto-installer)?** → If yes, it shows up under Tools section.
3. **Does it need to talk to an external server/cluster (SonarQube server, K8s API, Slack webhook)?** → If yes, needs System/Cloud config with credentials.
4. **Does the actual binary/daemon need to run on the executing machine regardless of Jenkins config?** → Almost always yes for compilers, scanners, and CLIs — Jenkins doesn't magically run code without the binary present, whether that binary got there via auto-install or manual `apt/pip install`.

## Pattern you'll notice

- **"Heavy" ecosystem tools with official first-party plugins** (Docker, Maven, Gradle, SonarQube Scanner, JDK) → tend to get full Tools-section treatment with auto-install.
- **"Simple CLI utility" tools** (Trivy, kubectl, flake8, Bandit, pytest) → usually no plugin at all, or a thin plugin that only parses report output — you install the binary yourself on the VM/agent, and Jenkins just shells out to it.
- **Tools that talk to a remote system** (SonarQube server, Kubernetes cluster, Slack) → need System/Cloud-level config for endpoint + credentials, separate from whether they have a Tools-section entry.
