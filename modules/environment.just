os := os()
# path_exists() is a boolean at conditional level; comparing it to "true"
# keeps the `if` on just's stable surface (no `set lists` / `--unstable`).
nurc := if path_exists(env("HOME") + "/.nurc") == "true" { "yes" } else { "no" }
env_name := if os == "linux" { "linux" } else if nurc == "yes" { "work" } else { "life" }
