# bitzer workstation · just as the task runner

import 'modules/environment.just'
import 'modules/installation.just'
import 'modules/connection.just'
import 'modules/linter.just'

cfg := if env_name == "linux" { "systems/linux/ansible.cfg" } else { "systems/macos/ansible.cfg" }
playbook := "systems/" + env_name + "/playbook.yml"

# usage: ./workstation <command> [entity]
@default:
    cat "{{ justfile_directory() }}/modules/usage.txt"

# ansible -m ping (sanity check)
@ping:
    ANSIBLE_CONFIG={{ cfg }} ansible -c local -m ping -i systems/hosts.ini Workstation

# run the ansible playbook for the host
@setup:
    ANSIBLE_CONFIG={{ cfg }} ansible-playbook -c local -i systems/hosts.ini \
      --vault-password-file systems/.vault_ --become-password-file systems/.become_ {{ playbook }}
