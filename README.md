# `~/.bitzer`

Multi-environment bitzer repository. A `justfile` dispatches to environment-specific Ansible playbooks that deploy configs via symlinks from `~/.bitzer/files/` into `$HOME` and `~/.config/`.

```
$ git clone <repo> ~/.bitzer
$ cd ~/.bitzer
$ ./workstation setup
```

## §0 · bootstrap

```
$ ./workstation setup
```

The `workstation` shell script detects the OS, installs `just` and `ansible` if missing (brew on macOS, dnf on Linux), then `exec`s `just --justfile justfile`. All dispatch lives in the justfile from that point on.

## §1 · environments

Three environments, partitioned by host signal (see `env_name` in the justfile):

| env     | host signal               | toolchain                                          |
| ------- | ------------------------- | -------------------------------------------------- |
| `work`  | macOS, work-env available | Scala 2 and Clojure, Work infrastructure           |
| `life`  | macOS, default            | Personal dev (SSH, git, Python, TS/JS, API tokens) |
| `linux` | Linux, `dnf` detected     | Same tooling as `life`, Fedora pkgs                |

## §2 · commands

The dispatcher is the justfile at the repo root. Each recipe takes an `entity` argument and dispatches on `"{{ env_name }}:{{ entity }}"`; unavailable combinations print `skipped: …` and exit 0.

| command          | work | life | linux |
| ---------------- | :--: | :--: | :---: |
| `ping`           |  ●   |  ●   |   ●   |
| `setup`          |  ●   |  ●   |   ●   |
| `lint`           |  ●   |  ●   |   ●   |
| `install scala2` |  ●   |  ·   |   ·   |
| `install python` |  ·   |  ●   |   ●   |
| `connect github` |  ·   |  ●   |   ●   |

Usage:

```
$ ./workstation <command> [entity]
```

## §3 · topology

```
~/.bitzer
├── workstation                  ◀── bash entry · OS detection · dep bootstrap
├── justfile                     ◀── command runner · ansible recipes
├── modules/                     ◀── just modules (environment · installation · connection)
│
├── systems/                     ◀── ansible config + roles
│   ├── hosts.ini                ◀── ansible inventory
│   ├── common/                  role: all environments (pkgs · npm · symlinks)
│   ├── macos/                   role: brew · ansible.cfg
│   ├── work/                    role: internal toolchain (Clojure · Scala) · playbook.yml
│   ├── life/                    role: personal · playbook.yml
│   └── linux/                   role: Fedora (dnf · COPR · mise) · ansible.cfg · playbook.yml
│
├── .github/workflows/lint.yml   ◀── CI (yamllint · ansible-lint · shellcheck · prettier)
└── files/                       ◀── managed bitzer (symlinked)
    ├── nvim/        ghostty/
    └── .zshrc  .zprofile  .life_profile  .linux_profile  .work_profile
```

Deployment invariant — files are **always** symlinked, never copied:

```
~/.bitzer/files/X    ◂─────── ln -s ───────▸    $HOME/X
```
