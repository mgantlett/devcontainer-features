# Nomos Dev Container Feature

Official [Dev Container Feature](https://containers.dev/implementors/features/) for [**Nomos**](https://github.com/mgantlett/nomos) (`Apache-2.0`) - installs the SHA-256 verified `nomos` static Go binary (`linux/amd64` and `linux/arm64`) inside GitHub Codespaces, DevPod, and VS Code / JetBrains Dev Containers.

## Usage (`.devcontainer/devcontainer.json`)

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mgantlett/devcontainer-features/nomos:1": {}
  }
}
```

### Pinning a Specific Release Version

```json
{
  "features": {
    "ghcr.io/mgantlett/devcontainer-features/nomos:1": {
      "version": "4.31.0"
    }
  }
}
```
