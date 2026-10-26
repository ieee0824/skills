# Skills

This repository is ieee0824's collection of reusable skills.

## Repository Structure

```text
global/
  AGENTS.md       Reusable agent instructions for general coding work
sandbox/
  SKILL.md        Skill for creating project sandboxes with Izanagi
```

Each skill lives in its own directory and uses `SKILL.md` as its entry point. Supporting scripts, references, or assets should be kept inside the same skill directory when needed.

## Tool Compatibility

Agent instruction discovery, filenames, placement, and precedence can differ between tools. Before using `global/AGENTS.md`, verify the target tool's current instructions; Codex, Claude, and other agents may require different locations or formats. Treat the file as reusable guidance rather than a universally installable configuration.

## Installation

Choose the target tool explicitly and preview the changes before installing:

```sh
./install.sh --tool codex --dry-run
./install.sh --tool codex

./install.sh --tool claude --dry-run
./install.sh --tool claude
```

The installer copies all skill directories into the selected tool's user-level skills directory. For Codex, it asks whether to launch Codex to merge or select global guidance, install all of `global/AGENTS.md`, or skip it. Codex-generated merge proposals are shown as a diff and require confirmation before installation. Use `--global-mode all` or `--global-mode skip` for non-interactive runs.

For Claude, the installer deliberately skips `global/AGENTS.md` because Claude uses different instruction filenames and precedence. Existing targets are preserved unless `--force` is supplied; replaced targets are moved to timestamped backups.
