# AGENTS.md

This file provides guidance to AI coding agents working in this repository.

## Architecture

Multi-environment bitzer repository. A `justfile` dispatches to environment-specific Ansible playbooks that deploy configs via symlinks from `~/.bitzer/files/` into `$HOME` and `~/.config/`.

### Environments

Three environments, resolved at runtime in the justfile from `os()` (`uname -s`) and `~/.nurc` presence:

- **work** (macOS + `~/.nurc`) — Nu infrastructure (Clojure and Scala 2 toolchains via the `work` role)
- **life** (macOS, default) — Personal dev: SSH, git, Python runtime (mise via `install python`), TS/JS toolchain (npm globals), API tokens (`GITHUB_TOKEN`, `ANTHROPIC_API_KEY`, `OLLAMA_API_KEY`)
- **linux** (Fedora, `dnf`) — Same tooling as life (Python, TS/JS) with Linux-specific packages

### Entry Point

```
./workstation <command> [entity]
```

The `workstation` shell script detects the OS to bootstrap deps (`just` + `ansible` via brew/dnf), then `exec`s `just --justfile justfile --working-directory "$script_dir"`. All dispatch lives in the justfile.

### Commands

The command registry is the justfile at the repo root. Each recipe takes an `entity` argument and dispatches on `"{{ env_name }}:{{ entity }}"`; unavailable combinations print `skipped: …` and exit 0.

| Command          | work | life | linux |
| ---------------- | :--: | :--: | :---: |
| `ping`           |  ●   |  ●   |   ●   |
| `setup`          |  ●   |  ●   |   ●   |
| `lint`           |  ●   |  ●   |   ●   |
| `install scala2` |  ●   |  ·   |   ·   |
| `install python` |  ·   |  ●   |   ●   |
| `connect github` |  ·   |  ●   |   ●   |

- `setup` runs the Ansible playbook for the host's environment (`cfg`/`playbook` variables set `ANSIBLE_CONFIG` and the playbook path).
- `lint` runs `yamllint` + `ansible-lint` (with the vault password when `systems/.vault_` exists; without it, the life and linux roles and their playbooks are excluded since their vaults can't decrypt) + `shellcheck`/`shfmt` + `prettier --check`. GitHub Actions runs it on every push/PR to the default branch (`.github/workflows/lint.yml`).
- `ping` runs `ansible -m ping` against localhost as a sanity check.
- `install scala2` installs the Scala 2 toolchain (JDK 11, Scala 2.12.19, sbt 1.9.9, scalafmt 2.7.5) via coursier (work only).
- `install python` installs the Python runtime via mise (`mise use -g python@latest`, life and linux). The pyright LSP and ruff formatter ship as global deps (npm), not under the mise Python.
- `connect github` authenticates with GitHub (SSH key + token + origin, life and linux).

### Directory Structure

```
workstation                    bash entry · OS detection · dep bootstrap
justfile                       command runner · ansible recipes · imports modules/
modules/                       just modules (imported, shared namespace)
  environment.just             env_name routing (life · work · linux)
  installation.just            install recipe
  connection.just              connect recipe
  usage.txt                    help text printed by the default recipe
.github/workflows/lint.yml     CI lint (yamllint · ansible-lint · shellcheck · prettier)
systems/                       ansible inventory · playbooks · roles, grouped per environment
  hosts.ini                    ansible inventory (Workstation → localhost)
  .vault_ .become_             vault and become password files (gitignored)
  common/                      role: all environments (pkgs · npm · symlinks)
  macos/                       role: shared Homebrew base · ansible.cfg (Darwin, python3, roles_path)
  linux/                       role: Fedora · ansible.cfg · playbook.yml
  life/                        role: personal · playbook.yml
  work/                        role: Nu toolchain (Clojure · Scala) · playbook.yml

requirements.yml               ansible collections (community.general)
files/                         managed bitzer (symlinked into $HOME / ~/.config)
```

### Ansible

Playbooks run against `localhost` via `hosts.ini` and declare the per-environment vars `host_profile` (`.life_profile` / `.work_profile` / `.linux_profile`) and `ghostty_config` (`built-in` / `linux`). The justfile sets `ANSIBLE_CONFIG=systems/macos/ansible.cfg` (macOS) or `ANSIBLE_CONFIG=systems/linux/ansible.cfg` (Linux) with the `cfg` variable, picks the playbook with the `playbook` variable, and passes `systems/.vault_` and `systems/.become_` as password files. The `common` role handles the shared topology: directories (`~/.ssh`, `~/.config`, `~/.config/ghostty`), shared packages + global npm packages (`become` only on Linux), nvim/host-profile/ghostty/.zprofile/.zshrc symlinks, `Transpile Fennel` (nfnl compiles `files/nvim/fnl/` → `lua/`), removal of stale symlinks and the Oh My Zsh install (tasks run in order base → security → environment → post). The `macos` role (shared by `life` and `work`) installs the shared Homebrew base plus `fennel-ls`. The `work` role overrides `git_user_email` (life and linux keep theirs in their vaulted vars) and installs `coursier` via Homebrew (used by the Scala 2 toolchain) plus the Clojure toolchain (`clojure`, `leiningen`, `clj-kondo`, `cljfmt`, `clojure-lsp-native`) via Homebrew taps (`clojure/tools`, `weavejester/brew`, `borkdude/brew`, `clojure-lsp/brew`). The `linux` role provisions Fedora: `dnf-plugins-core`, COPR repos (`scottames/ghostty`, `iucar/duckdb`, `dejan/lazygit`, `jdxcode/mise`), `lua-language-server` via mise, and builds `fennel-ls` from source. Every macOS-based role also installs Pi (`curl -fsSL https://pi.dev/install.sh | sh`) — idempotent via a `command -v pi` check.

`roles_path = ..` in each `ansible.cfg` is relative to the `.cfg` location and resolves to the `systems/` directory, so every role lives next to its playbook.

### Neovim

Plugin manager: lazy.nvim. Leader: Space, local leader: comma.

Source of truth is Fennel under `files/nvim/fnl/` (`settings.fnl` + `mappings.fnl` + `plugins/*.fnl`); the `lua/` tree is generated by nfnl on save and is gitignored (only `lua/plugins.lua` is committed as the bootstrap). `settings.fnl` defines vim options and explicitly invokes `(mappings.general)`, `(mappings.window)`, `(mappings.lsp)` so the keymaps are actually registered. `mappings.fnl` exports a module `(local M {})` with functions `M.general`, `M.window`, `M.lsp`, `M.telescope`, `M.oil`, `M.autocomplete`.

LSP uses the new `vim.lsp.config`/`vim.lsp.enable` API (not the old `lspconfig.setup`), plus nvim-metals for Scala (**work only** — gated on `NU_HOME`, Scala 2 settings via `JHFM`). Configured LSPs: html, sqls, ts_ls, lua_ls, yamlls, bashls, jsonls, tofu_ls, ansiblels, clojure_lsp, pyright, **fennel_ls**. Formatting is handled by conform.nvim (stylua for Lua, **fnlfmt for Fennel**, cljfmt for Clojure, scalafmt for Scala (work), prettier for JSON/markdown/JS/TS/HTML, ruff for Python, LSP fallback for others). LSP provides diagnostics and code actions.

Treesitter parsers: lua, sql, css, bash, yaml, json, html, scala (work), clojure, javascript, typescript, embedded_template, **fennel**, python. ERB is covered by `embedded_template` plus the `html` tree registered for `mustache`. Completion via nvim-cmp with LuaSnip and cmp-nvim-lsp. Paredit is enabled for `clojure` and `fennel` filetypes.

#### Fennel gotchas

These cost real time during the migration, watch for them:

1. **Top-level `require` of a lazy plugin fails** with `module 'X' not found` when lazy loads the spec. The plugin is not on the runtimepath yet. Move the `require` inside the `:config` lambda, or declare the spec with `:dependencies` so lazy loads it first.
2. **`cmp_nvim_lsp.default_capabilities` is a function, not a value.** Pass the result of calling it (`(require :cmp_nvim_lsp).default_capabilities()`), not the field. Otherwise `vim.tbl_deep_extend` raises `expected table, got function`.
3. **Never drop the leading `:` on a keyword.** A keyword like `:.git/` or `:ui-select` always compiles to the string `".git/"` / `"ui-select"`, special characters included — there's no need to write it as a quoted string. The real danger is _omitting_ the colon: a bare symbol like `ui-select` (no `:`) compiles to a reference to an undefined global variable instead of a string, and silently breaks lookups.
4. **Wildcard LSP config** — `(vim.lsp.config "*" {...})` applies to every LSP. When it touches `capabilities`, wrap the value in a function so it is computed lazily (otherwise `cmp_nvim_lsp` is required at load time and may not be ready).
5. **Empty function body** — `(fn [])` does not compile. Use `(fn [] nil)`.
6. **Keymaps defined in `mappings.fnl` are not registered automatically.** `M.general` etc. are just functions; `settings.fnl` must call them. Forgetting this silently breaks `<leader>q` and friends.
7. **Compiling outside a fennel buffer** — nfnl's ftplugin only triggers on buffer open. To compile a single file from a script or `--headless`:
   ```
   nvim --headless -c "lua require('nfnl.api')['compile-file']({ path = './fnl/x.fnl' })" -c "qa!"
   ```
8. **nfnl does not delete orphans.** Removing a `fnl/plugins/*.fnl` source leaves the stale generated `.lua` behind, and lazy picks specs from `lua/plugins/`. Delete `lua/{settings,mappings}.lua` and `lua/plugins/` after removing a source, then re-run `compile-all-files`.

### Profile System

`.zprofile` sources up to four profile files in order: `~/.life_profile`, `~/.work_profile`, `~/.linux_profile`, `~/.private_profile`. Life, work, and linux profiles are symlinked by Ansible. On life/linux, `.private_profile` is a real file at `$HOME` written in place by `Propagate API Tokens` (`no_log`, mode 0600); on work it stays a symlink to `files/.private_profile`. Profiles contain environment variables, PATH entries, and project aliases. The `work` profile adds Nu/Flutter/Python/Go/Node/Coursier paths. `.zshrc` has no environment gating — work sources neither life nor linux profile, and `~/.nurc` marks the work environment.

### Secrets

Ansible Vault encrypts `systems/life/vars/main.yml` and `systems/linux/vars/main.yml` (tokens: `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`, `OLLAMA_API_KEY`; life also holds VPS SSH template vars). The life and linux roles write tokens directly to `~/.private_profile` — never into the repository tree. `git_user_email` lives in each environment's vars (vaulted for life and linux, plain in `systems/work/vars/main.yml`).

## Key Conventions

- Ansible task names use Title Case (e.g., `Install Dependencies`).
- Config deployment is always via symlinks — never copy files into `$HOME`.
- Ghostty has two configs: `built-in` (all macOS) and `linux`, routed by the `ghostty_config` playbook var.
- The `workstation` script must be run from the repo root (`~/.bitzer/`).
- The justfile and `modules/*.just` are the source of truth for the workstation commands and the environment routing (`env_name` in `modules/environment.just`). Update them and `AGENTS.md` together when changing it.
- Use `prettier . --write` to format Markdown files, `just --fmt` for the justfile, `stylua .` for Lua, `ruff . --fix` for Python, and `fnlfmt` for Fennel (handled by `conform.nvim` in the editor).
- `just lint` must stay green: `yamllint`, `ansible-lint` (skips listed in `.ansible-lint`; vaulted vars files excluded via `exclude_paths`), `shellcheck`, `shfmt`, `prettier --check`.
- Don't write comments. If you do, keep them brief.

## Direction

End state: Fennel Neovim config, justfile + sh CLI, Ansible deployment. The managed languages are Scala 2, Clojure (work), TS/JS + Python (life/linux), Fennel (editor). Remaining work lives in the roles if the playbooks grow.
