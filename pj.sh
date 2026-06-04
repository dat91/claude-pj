# pj — fuzzy-pick a project from Claude history, cd into it, launch Claude.
# Portable POSIX sh: works sourced in bash (incl. 3.2) and zsh, macOS or Linux.
# Projects come from ~/.claude/projects; the real path is read from each
# session's "cwd" (decoding the dir name is lossy: / and . both become -).
# Usage:  pj [query]     query pre-filters the fzf list

# Emit rows "count<TAB>date<TAB>path", deduped per path (highest count), count desc.
_pj_rows() {
  projroot="${HOME}/.claude/projects"
  [ -d "$projroot" ] || return 1
  find "$projroot" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while IFS= read -r d; do
    # newest *.jsonl in this dir, by mtime — avoid globbing (zsh aborts on no match)
    names=$(ls -t "$d" 2>/dev/null | grep '\.jsonl$')
    [ -n "$names" ] || continue
    cnt=$(printf '%s\n' "$names" | grep -c .)
    latest="$d/$(printf '%s\n' "$names" | head -1)"
    cwd=$(grep -o '"cwd":"[^"]*"' "$latest" 2>/dev/null | head -1 | sed 's/.*"cwd":"//; s/"$//')
    [ -n "$cwd" ] && [ -d "$cwd" ] || continue
    [ "$cwd" = "$HOME" ] && continue
    case "$cwd" in /Applications/*|*/Library/*) continue ;; esac
    # macOS (BSD) stat first, then GNU stat fallback
    date=$(stat -f '%Sm' -t '%Y-%m-%d' "$latest" 2>/dev/null \
           || stat -c '%y' "$latest" 2>/dev/null | cut -d' ' -f1)
    printf '%s\t%s\t%s\n' "$cnt" "$date" "$cwd"
  done | sort -t"$(printf '\t')" -k3,3 -k1,1nr \
       | awk -F'\t' '!seen[$3]++' \
       | sort -t"$(printf '\t')" -k1,1nr
}

pj() {
  rows=$(_pj_rows)
  [ -n "$rows" ] || { echo "pj: no projects found" >&2; return 1; }

  if command -v fzf >/dev/null 2>&1; then
    sel=$(printf '%s\n' "$rows" \
      | awk -F'\t' '{printf "%s\t%4d  %s  %s\n",$3,$1,$2,$3}' \
      | fzf --delimiter='\t' --with-nth=2 --query="${1:-}" \
            --height=60% --reverse --border \
            --prompt='project > ' --header='sessions  last-used  path' \
      | cut -f1)
  else
    printf '%s\n' "$rows" | awk -F'\t' '{printf "%3d) %s\n", NR, $3}'
    printf 'select #: '
    read n
    sel=$(printf '%s\n' "$rows" | awk -F'\t' -v n="$n" 'NR==n{print $3}')
  fi

  [ -n "$sel" ] || return 0
  cd "$sel" && claude --dangerously-skip-permissions
}
