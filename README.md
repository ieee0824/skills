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
