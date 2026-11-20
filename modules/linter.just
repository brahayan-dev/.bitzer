# lint yaml · ansible · shell · markdown
@lint:
    #!/usr/bin/env bash
    set -euo pipefail
    export ANSIBLE_DEPRECATION_WARNINGS=False
    export ANSIBLE_ROLES_PATH="$PWD/systems"
    git ls-files '*.yml' '*.yaml' | xargs --no-run-if-empty yamllint
    if ! [[ -d "$HOME/.ansible/collections/ansible_collections/community/general" ]]; then
      ansible-galaxy collection install -r requirements.yml >/dev/null
    fi
    if [[ -f systems/.vault_ ]]; then
      ANSIBLE_VAULT_PASSWORD_FILE="$PWD/systems/.vault_" ansible-lint systems
    else
      ansible-lint --exclude systems/life --exclude systems/linux
    fi
    git ls-files '*.sh' | xargs --no-run-if-empty shellcheck
    git ls-files '*.sh' | xargs --no-run-if-empty shfmt -d
    npx --yes prettier --check .
