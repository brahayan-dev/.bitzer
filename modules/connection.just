# authenticate with the remote forge (life | linux)
@connect entity:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ env_name }}:{{ entity }}" in
      life:github | linux:github)
        git remote set-url origin git@github.com:brahayan-dev/.bitzer.git
        gh auth login
        gh auth refresh -h github.com -s admin:ssh_signing_key
        gh ssh-key add "$HOME/.ssh/$(whoami)_rsa.pub" -t "$(hostname)"
        ;;
      *)
        echo "skipped: {{ entity }} is not available on {{ env_name }}"
        ;;
    esac
