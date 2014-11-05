#!/usr/bin/fish

for line in (cat hosts.ini)
    ssh-keyscan $line >> ~/.ssh/known_hosts
end

ansible-playbook -i hosts.ini bootstrap.yml --user root