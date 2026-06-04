# claude-pj

Fuzzy-jump to any project you've worked on in [Claude Code](https://claude.com/claude-code), then launch Claude there.

`pj` reads `~/.claude/projects`, recovers each project's real path from its session history, and presents an [fzf](https://github.com/junegunn/fzf) picker sorted by session count. Pick one — it `cd`s in and starts `claude`.

```
project > api
sessions  last-used  path
  80  2026-06-04  /Users/you/code/api-server
  52  2026-05-26  /Users/you/code/web-app
  42  2026-06-04  /Users/you/code/oss/some-tool
  ...full history...
```

## Why not just decode the directory names?

Claude stores history under `~/.claude/projects/<encoded-path>/`, where the
encoding replaces both `/` and `.` with `-` — a lossy transform you can't
reverse. `pj` instead reads the real `"cwd"` field from each session's `.jsonl`,
so the paths are always accurate.

## Install

Requires `fzf` (optional — falls back to a numbered menu), plus standard
`find`/`grep`/`sed`/`awk`/`sort`/`stat`. Works on macOS and Linux, in bash or zsh.

```sh
git clone https://github.com/dat91/claude-pj.git
echo '[ -f ~/path/to/claude-pj/pj.sh ] && source ~/path/to/claude-pj/pj.sh' >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
```

`pj` must be **sourced** (it's a shell function, not a script) so its `cd` can
move your interactive shell.

## Usage

```sh
pj            # open the picker
pj api        # open the picker pre-filtered to "api"
```

Edit the final line of `pj.sh` if you don't want `--dangerously-skip-permissions`.

## License

MIT
