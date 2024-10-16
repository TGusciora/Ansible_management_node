# Use Ubuntu 22.04 as the base image
FROM mirror.gcr.io/library/ubuntu:22.04

# Avoid prompts from apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
	less \
    software-properties-common \
    openssh-client \
    python3-pip \
    vim \
	inetutils-ping \
    iputils-tracepath \
    ipv6calc \
    && apt-add-repository --yes --update ppa:ansible/ansible \
    && apt-get install -y ansible vim yamllint \
	# below can be commented out for lighter container if no connectivity issues 
	&& apt-get install -y iputils-ping iproute2 curl traceroute\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install ansible-dev-tools and ansible-lint
RUN pip3 install ansible-dev-tools ansible-lint

# Set the working directory
WORKDIR /root/ansible_playbooks
# add .ssh folder to working directory
RUN mkdir -p /root/ansible_playbooks/.ssh
# add permissions so ansible can run the code
RUN chmod 700 /root/ansible_playbooks/.ssh

# Create directory for Ansible configuration
RUN mkdir -p /root/ansible_config

# Create directory for Ansible roles
RUN mkdir -p /root/ansible_roles

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# copy playbooks
COPY ansible_playbooks/site.yaml /root/ansible_playbooks/site.yaml

# copy roles folder
COPY ansible_roles /root/ansible_roles


# Conditionally copy hosts and ansible.cfg
COPY ansible_config/hosts* /root/ansible_config/hosts
COPY ansible_config/ansible.cfg* /root/ansible_config/ansible.cfg

# Set correct permissions for SSH keys
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# ENV ANSIBLE_CONFIG=/root/ansible_config/ansible.cfg
# ENV ANSIBLE_INVENTORY=/root/ansible_config/hosts
# ENV ANSIBLE_ROLES_PATH=/root/ansible_roles

# Vim configuration - adding line numbers and syntax highlighting, backspace working as delete, invoke vim settings (newer) instaed of vi
RUN echo "set nocompatible\nset backspace=indent,eol,start\nset number\nsyntax on" > /root/.vimrc

# default ansible config file with most of the modules disabled
RUN ansible-config init --disabled -t all >/etc/ansible/ansible.cfg

RUN echo "source /tmp/ssh-agent-env" >> /root/.bashrc

CMD ["/bin/bash"]
