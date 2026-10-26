#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tool=""
force=false
dry_run=false
global_mode="ask"

usage() {
    cat <<'EOF'
Usage: ./install.sh --tool codex|claude [--global-mode ask|all|skip] [--force] [--dry-run]

Installs every directory containing SKILL.md into the selected tool's
user-level skills directory.

Options:
  --tool TOOL  Target Codex or Claude Code (required)
  --global-mode MODE
               For Codex, ask how to handle global instructions, install all,
               or skip them (default: ask)
  --force      Back up and replace existing targets
  --dry-run    Print planned changes without writing files
  -h, --help   Show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --tool)
            shift
            tool="${1:-}"
            ;;
        --tool=*)
            tool="${1#*=}"
            ;;
        --force)
            force=true
            ;;
        --global-mode)
            shift
            global_mode="${1:-}"
            ;;
        --global-mode=*)
            global_mode="${1#*=}"
            ;;
        --dry-run)
            dry_run=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

case "$tool" in
    codex)
        tool_root="${CODEX_HOME:-$HOME/.codex}"
        skills_root="$tool_root/skills"
        ;;
    claude)
        tool_root="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
        skills_root="$tool_root/skills"
        ;;
    *)
        echo "--tool must be codex or claude" >&2
        usage >&2
        exit 2
        ;;
esac

case "$global_mode" in
    ask|all|skip) ;;
    *)
        echo "--global-mode must be ask, all, or skip" >&2
        exit 2
        ;;
esac

timestamp="$(date +%Y%m%d%H%M%S)"
sources=()
targets=()
labels=()

install_path() {
    local source_path="$1"
    local target_path="$2"
    local label="$3"
    local backup_path

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        backup_path="${target_path}.backup.${timestamp}.$$"
        if [ "$dry_run" = true ]; then
            echo "Would back up $target_path to $backup_path"
        else
            mv "$target_path" "$backup_path"
            echo "Backed up $target_path to $backup_path"
        fi
    fi

    if [ "$dry_run" = true ]; then
        echo "Would install $label at $target_path"
        return
    fi

    mkdir -p "$(dirname "$target_path")"
    cp -R "$source_path" "$target_path"
    echo "Installed $label at $target_path"
}

install_all_global_instructions() {
    local target_path="$tool_root/AGENTS.md"

    if { [ -e "$target_path" ] || [ -L "$target_path" ]; } && [ "$force" != true ]; then
        echo "Existing global Codex instructions: $target_path" >&2
        echo "Use the interactive merge or re-run with --force and --global-mode all." >&2
        return 1
    fi
    install_path "$repo_root/global/AGENTS.md" "$target_path" "global Codex instructions"
}

merge_global_with_codex() {
    local target_path="$tool_root/AGENTS.md"
    local merge_dir proposed_path reference_path answer

    if ! command -v codex >/dev/null 2>&1; then
        echo "Codex CLI is not available; global instructions were not changed." >&2
        return 1
    fi

    merge_dir="$(mktemp -d "${TMPDIR:-/tmp}/skills-global-merge.XXXXXX")"
    proposed_path="$merge_dir/merged-AGENTS.md"
    cp "$repo_root/global/AGENTS.md" "$merge_dir/candidate-AGENTS.md"
    if [ -f "$target_path" ]; then
        cp "$target_path" "$merge_dir/existing-AGENTS.md"
        reference_path="$merge_dir/existing-AGENTS.md"
    else
        : > "$merge_dir/existing-AGENTS.md"
        reference_path="/dev/null"
    fi

    echo "Launching Codex to review existing and candidate global instructions."
    echo "Choose whether to merge all guidance, select only useful sections, or skip."
    codex --no-alt-screen -C "$merge_dir" -s workspace-write -a on-request \
        "Compare existing-AGENTS.md with candidate-AGENTS.md. Ask me whether to merge all candidate guidance, select particular sections, or skip installation. Preserve compatible existing instructions and avoid duplicates or contradictions. Do not modify the source files. If I approve a result, write only the proposed complete Markdown document to merged-AGENTS.md. If I choose skip, do not create that file."

    if [ ! -s "$proposed_path" ]; then
        echo "No merged global instructions were produced; leaving the existing file unchanged."
        rm -rf "$merge_dir"
        return
    fi

    echo "Proposed global instruction changes:"
    diff -u "$reference_path" "$proposed_path" || true
    printf 'Install this proposal? [y/N] '
    read -r answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            install_path "$proposed_path" "$target_path" "merged global Codex instructions"
            ;;
        *)
            echo "Global instructions were not changed."
            ;;
    esac
    rm -rf "$merge_dir"
}

skill_count=0
while IFS= read -r skill_file; do
    skill_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$skill_dir")"
    sources+=("$skill_dir")
    targets+=("$skills_root/$skill_name")
    labels+=("skill '$skill_name'")
    skill_count=$((skill_count + 1))
done < <(find "$repo_root" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print | sort)

if [ "$skill_count" -eq 0 ]; then
    echo "No skills found under $repo_root" >&2
    exit 1
fi

conflict_count=0
if [ "$force" != true ]; then
    for index in "${!targets[@]}"; do
        if [ -e "${targets[$index]}" ] || [ -L "${targets[$index]}" ]; then
            echo "Existing ${labels[$index]}: ${targets[$index]}" >&2
            conflict_count=$((conflict_count + 1))
        fi
    done
fi

if [ "$conflict_count" -gt 0 ]; then
    echo "No files were changed. Re-run with --force to back up and replace existing targets." >&2
    exit 1
fi

for index in "${!sources[@]}"; do
    install_path "${sources[$index]}" "${targets[$index]}" "${labels[$index]}"
done

if [ "$tool" = codex ]; then
    if [ "$dry_run" = true ]; then
        case "$global_mode" in
            ask) echo "Would ask whether to use Codex to merge/select, install all, or skip global instructions." ;;
            all) echo "Would install all global Codex instructions at $tool_root/AGENTS.md." ;;
            skip) echo "Would skip global Codex instructions." ;;
        esac
    else
        selected_mode="$global_mode"
        if [ "$selected_mode" = ask ]; then
            if [ -t 0 ] && [ -t 1 ]; then
                echo "Global Codex instructions:"
                echo "  1) Launch Codex to merge or select guidance"
                echo "  2) Install all guidance"
                echo "  3) Skip"
                printf 'Choose [1-3]: '
                read -r answer
                case "$answer" in
                    1) selected_mode="assist" ;;
                    2) selected_mode="all" ;;
                    *) selected_mode="skip" ;;
                esac
            else
                echo "Non-interactive session: skipped global Codex instructions."
                echo "Use --global-mode all or run interactively to merge/select them."
                selected_mode="skip"
            fi
        fi
        case "$selected_mode" in
            assist) merge_global_with_codex ;;
            all) install_all_global_instructions ;;
            skip) echo "Skipped global Codex instructions." ;;
        esac
    fi
else
    echo "Skipped global/AGENTS.md: Claude uses different instruction filenames and precedence."
    echo "Adapt it deliberately for the intended Claude scope instead of installing it unchanged."
fi

if [ "$dry_run" = true ]; then
    echo "Dry run complete for $tool."
else
    echo "Installed $skill_count skill(s) for $tool."
fi
