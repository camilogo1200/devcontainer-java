# 🚀 Quick-Start Checklist & Toolset Overview

Follow these steps to spin up your **DevContainer** and explore the comprehensive toolchain included in the image.

---

## 1  Clone or create your project folder

```bash
git clone <your-repo> my-project
cd my-project
```

---

## 2  Add the Docker assets

```
my-project/
├─ Dockerfile
├─ post-setup.sh
└─ entrypoint.sh
```

> **Tip:** Copy the three files into this directory or pull them from your configuration repository.

---

## 3  Make the helper scripts executable

```bash
chmod +x post-setup.sh entrypoint.sh
```

---

## 4  Build the image

```bash
docker build -t my-devcontainer:latest .
```

---

## 5  Run the container (interactive shell)

```bash
docker run -it --rm -v "$PWD":/workspace my-devcontainer
```

The volume mount keeps your source code on the host while making it available inside the container at `/workspace`.

---

# 🧰 What’s inside the image?

A complete inventory of frameworks, runtimes, and utilities—ready out of the box:

## ☕ Java & JVM Toolchain

| Component | Version | Purpose |
|-----------|---------|---------|
| **Amazon Corretto JDK** | 17-alpine | Production-grade LTS JDK |
| **Apache Maven** | 3.9.10 | Build & dependency management |
| **MAVEN_OPTS** | pre-set | Local repo persisted at `/workspace/.m2` |

---

## 🟩 Node & Front-End Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| **Node.js** | 20 (Alpine `20.15.1-r0`) | Modern LTS JavaScript runtime |
| **npm** | Bundled | Node package manager |
| **Yarn** | Installed by `post-setup.sh` | Alternative package manager |
| **@eslint/cli** | Installed by `post-setup.sh` | Linting for JS/TS projects |

---

## 🐍 Python Ecosystem

| Component | Version | Purpose |
|-----------|---------|---------|
| **Python** | 3.x (Alpine) | Scripting, automation, data tasks |
| **pip / wheel** | Latest via `post-setup.sh` | Package installation & builds |

---

## 🔗 SCM & Binary Assets

| Tool | Notes |
|------|-------|
| **git** | Source-control powerhouse |
| **git-lfs** | Large-file storage (auto-initialized) |

---

## 🔧 CLI Utilities

| Utility | Role |
|---------|------|
| `bash`, `coreutils`, `curl`, `wget` | Shell & core commands |
| `zip`, `unzip`, `gzip`, `tar`, `rsync` | Compression & sync |
| `openssh-client`, `sshpass` | Secure copy / scripted SSH |
| `openssl` | TLS & certificate tooling |
| `sudo` (NOPASSWD) | Elevated commands for the `app` user |
| `ca-certificates` | Trusted root CAs |

---

## 🏁 Runtime Entry Point

Every container start triggers **`entrypoint.sh`**, which:

1. Prints key tool versions (Java, Node, Maven, Yarn).  
2. Performs first-run checks (e.g., primes Yarn cache).  
3. Hands control to the given command (default is `bash`).

---

## 🛡️ Health Check

Docker’s built-in `HEALTHCHECK` validates Java, Node, and Maven every 30 seconds, enabling orchestration systems to mark the container **healthy**.

---

### 🎉 You’re ready!

The image delivers a **full-stack Java + Node + Python** toolbox—ideal for monorepos, microservices, and polyglot development—fully reproducible and DevContainer-friendly.
