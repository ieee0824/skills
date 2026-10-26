---
name: sandbox
description: Create or update a project development sandbox powered by ieee0824/izanagi. Use when a repository needs Izanagi configuration, a pinned development image, helper commands, or documentation for isolated local development. Do not use for generic containers or CI-only environments that do not use Izanagi.
---

# Izanagi Project Sandbox

Build a project-specific development sandbox with [Izanagi](https://github.com/ieee0824/izanagi). Adapt the result to the target project's language, tools, platform, and trust boundary.

## Discover the Environment

Inspect the repository before editing. Identify its build and test commands, required toolchains, lockfiles, host platform, existing container files, and whether Izanagi is already configured. Check the current Izanagi documentation and releases rather than assuming flags, configuration keys, image names, or versions.

Ask only when a decision cannot be inferred safely, especially whether the shared project must be writable and which sandbox backend or container runtime is available.

## Design the Sandbox

- Prefer Izanagi's native backend for a simple sandbox that needs no custom image. Use an Apple Container or QEMU-backed image when the project needs a reproducible toolchain or stronger isolation.
- Pin base images, toolchains, package versions, and the Izanagi release used to build the guest agent. Keep the Izanagi base and agent versions aligned.
- Keep the active Izanagi configuration outside the shared workspace. Commit only a reviewed example such as `.izanagi/izanagi.toml.example`; initialize the project-specific configuration with `izanagi init`.
- Default shared paths to `read_only = true`. Set `read_only = false` only when sandboxed tools must edit the checkout, and explain that changes affect the host directly. Prefer a disposable copy for untrusted code.
- Never bake credentials into an image or broadly mount host credential directories. Add narrowly scoped, explicit runtime authentication only when requested, document its authority, and clean up copied credentials on startup and shutdown.
- Do not claim network isolation merely because execution is containerized. Describe the actual network and tracing configuration.

## Create Project Files

Produce a complete, operable integration rather than a generic configuration snippet. For a custom-image setup, keep the image, Izanagi configuration, lifecycle commands, project commands, cleanup behavior, and user documentation consistent with one another.

Add only what the project needs. A custom-image setup commonly contains:

```text
.izanagi/
  Dockerfile
  izanagi.toml.example
scripts/
  sandbox
```

Make the helper script a small command dispatcher for relevant operations such as `build-base`, `build`, `up`, `down`, `shell`, `test`, and `logs`. Each command must perform the real project operation rather than serve as a placeholder. Use the repository's actual commands and keep build artifacts inside the guest when practical. Make cleanup idempotent, fail clearly when prerequisites are missing, and avoid embedding machine-specific absolute paths.

Document installation prerequisites, configuration initialization, the build/start/use/stop flow, shared-path write implications, network behavior, and any credential handoff. Keep generated instructions consistent with the files and commands actually created.

## Validate

Run syntax and formatting checks for every generated file. When the required runtime is available, build the image, initialize a non-sensitive test configuration, start the sandbox, execute a harmless command and the project's smallest relevant check, inspect suspicious logs, and stop the sandbox. Do not weaken isolation or bypass a failed security check merely to make validation pass. Report anything that could not be exercised and why.
