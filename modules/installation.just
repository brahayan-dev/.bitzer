# install a toolchain (scala2 | python)
@install entity:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ env_name }}:{{ entity }}" in
      work:scala2)
        dir="$HOME/.local/share/coursier/bin"
        coursier java --jvm temurin:11 --setup
        coursier install sbt:1.9.9
        coursier install scalafmt:2.7.5
        coursier install metals --install-dir "$dir"
        coursier install scala:2.12.19 scalac:2.12.19
        ;;
      life:python | linux:python)
        mise use -g "python@latest"
        ;;
      *)
        echo "skipped: {{ entity }} is not available on {{ env_name }}"
        ;;
    esac
