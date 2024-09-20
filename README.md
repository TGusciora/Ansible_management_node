# Ansible_management_node
Management node for ansible - dockerized. Created to manage VPS with ipv6 address only.

Caution: In my case I am using Windows 11 with WSL (Windows Subsystem for Linux) and creating docker instance inside WSL to server as ansible management node.

#Linux directory for mounting (im my case)
cd /mnt/c/users/tgusc/documents/github/ansible_management_node

Useful docker commands:
1. Re-build detached image (if any underlying files changed)
docker-compose up -d --build

1. Build and start the container (detached). You have to be in directory with docker files
docker-compose up -d

2. Access the container
docker-compose exec ansible bash

3. Stop the container after you are done
docker-compose down

4. View logs
docker-compose logs

5. Check docker names
docker ps

6. Copy files from local to container
docker cp .\path\to\local\file ansible:/path/in/container/

7. Copy files from container to local
docker cp ansible_management_node-ansible-1:/etc/ansible/ansible.cfg .\ansible_config\ansible.cfg

8. Running with full logs
docker-compose up --build && docker-compose logs -f ansible


Powershell Version : docker-compose up --build; if ($?) { Write-Host "Build successful, following logs:" -ForegroundColor Green; docker-compose logs -f ansible } else { Write-Host "Build failed" -ForegroundColor Red }
# close with ctrl+ c

10. test ssh connection with VPS
ssh user@hostname/ip

ping ip

traceroute6 ip

11. Check your docker connectivity settings
docker network inspect bridge

12. Clean networks and containers
docker-compose down
docker network prune

inside docker:
# look for inet6 entries 
ip -6 neigh show
ip -6 neigh show


# WSL Preparation - in order to be able to properly connect to ipv6 VPS from WSL container

## WSL SSH connection Check
# 1. Need to establish permissions and settings
# https://devblogs.microsoft.com/commandline/automatically-configuring-wsl/
# https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/
sudo vim /etc/wsl.conf
```
[boot]
systemd=true

[automount]
options = "metadata"
```

# Or alternative create file by code without vim
sudo tee /etc/wsl.conf > /dev/null <<EOT
[boot]
systemd=true
[automount]
options = "metadata"
EOT
# end alternative

# configure WSL2 on Windows /users/user/.wslconfig file
# https://learn.microsoft.com/en-us/windows/wsl/networking#mirrored-mode-networking
```
[wsl2]
networkingMode=mirrored
```

# install ssh on WSL + change permissions on SSH keys to maintain security requirements
sudo apt update
sudo apt install openssh-server
eval $(ssh-agent -s)
chmod 700 /mnt/c/users/tgusc/.ssh
chmod 600 /mnt/c/users/tgusc/.ssh/id_ed25519
chmod 644 /mnt/c/users/tgusc/.ssh/id_ed25519.pub
chmod 600 /mnt/c/users/tgusc/.ssh/mikrus
chmod 644 /mnt/c/users/tgusc/.ssh/mikrus.pub
cd /mnt/c/users/tgusc/.ssh
ls -la /mnt/c/users/tgusc/.ssh
# add ssh-keys to agent
ssh-add /mnt/c/users/tgusc/.ssh/id_ed25519
ssh-add /mnt/c/users/tgusc/.ssh/mikrus
ssh-add -l

# Connecting with SSH via agent
ssh -A -p user@hostname/ip (działa)

# Encountered issues
1) If you can't see letters in your CLI no more (because you copied commands from windows to WLS Unix for example) use below command:
reset