#!/bin/bash
set -e

echo "Starting entrypoint script..."

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}


# Test IPv6 connectivity
log "Testing IPv6 connectivity"
if ping6 -c 3 ipv6.google.com > /dev/null 2>&1; then
    log "IPv6 Google connectivity confirmed"
else
    log "IPv6 connectivity failed. Please check your network configuration."
    exit 1
fi


# Copy SSH keys from secrets and set permissions
log "Copying SSH keys from secrets"
mkdir -p /root/.ssh
cp /run/secrets/ssh_ansible_private_key /root/.ssh/id_ed25519
cp /run/secrets/ssh_ansible_public_key /root/.ssh/id_ed25519.pub
cp /run/secrets/ssh_mikrus_private_key /root/.ssh/mikrus
cp /run/secrets/ssh_mikrus_public_key /root/.ssh/mikrus.pub
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_ed25519
chmod 644 /root/.ssh/id_ed25519.pub
chmod 600 /root/.ssh/mikrus
chmod 644 /root/.ssh/mikrus.pub

# Verify key contents (only show first line for security)
log "Verifying SSH key contents:"
head -n 1 /root/.ssh/id_ed25519
head -n 1 /root/.ssh/id_ed25519.pub
head -n 1 /root/.ssh/mikrus
head -n 1 /root/.ssh/mikrus.pub

# Start SSH agent and save environment variables
log "Starting SSH agent"
eval $(ssh-agent -s)
echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > /tmp/ssh-agent-env
echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> /tmp/ssh-agent-env

log "SSH agent started with PID $SSH_AGENT_PID"

# Add SSH key to the agent
log "Adding SSH key to the agent"
if ssh-add /root/.ssh/id_ed25519; then
    log "Successfully added SSH key to the agent"
else
    log "Failed to add SSH key to the agent"
    log "SSH key file contents:"
    cat /root/.ssh/id_ed25519
    log "SSH agent environment:"
    env | grep SSH
fi

if ssh-add /root/.ssh/mikrus; then
    log "Successfully added SSH key to the agent"
else
    log "Failed to add SSH key to the agent"
    log "SSH key file contents:"
    cat /root/.ssh/mikrus
    log "SSH agent environment:"
    env | grep SSH
fi

# List added identities
log "Listing identities:"
ssh-add -l || log "No identities found"

# Additional debugging information
log "Contents of /root/.ssh:"
ls -la /root/.ssh/

log "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
log "SSH_AGENT_PID: $SSH_AGENT_PID"

# Ensure SSH agent environment is sourced in interactive shells
echo "source /tmp/ssh-agent-env" >> /root/.bashrc



# Function to copy default config if it doesn't exist
copy_default_config() {
    local file=$1
    local default_path="/etc/ansible/$file"
    local config_path="/root/ansible_config/$file"

    echo "Checking for $file..."
    if [ ! -s "$config_path" ]; then
        echo "Copying default $file from $default_path to $config_path..."
        cp "$default_path" "$config_path"
        echo "Default $file copied successfully."
    else
        echo "$file already exists in /ansible_config. Using existing file."
    fi
    echo "Content of $config_path:"
    cat "$config_path"
}

# Copy default configs if they don't exist
copy_default_config "hosts"
copy_default_config "ansible.cfg"

# Ensure Ansible uses the correct config
export ANSIBLE_CONFIG=/root/ansible_config/ansible.cfg
export ANSIBLE_INVENTORY=/root/ansible_config/hosts

# Modify shell initialization
echo "source /tmp/ssh-agent-env" >> /root/.bashrc

echo "Entrypoint script completed. Executing main command..."

# Execute the main command
exec "$@"
