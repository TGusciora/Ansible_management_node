# Use Ubuntu 22.04 as the base image
FROM mirror.gcr.io/library/ubuntu:22.04

# Avoid prompts from apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    openssh-client \
    python3-pip \
    vim \
	inetutils-ping \
    iputils-tracepath \
    ipv6calc \
    && apt-add-repository --yes --update ppa:ansible/ansible \
    && apt-get install -y ansible vim  \
	# below can be commented out for lighter container if no connectivity issues 
	&& apt-get install -y iputils-ping iproute2 curl traceroute\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /ansible

# Create directory for Ansible configuration
RUN mkdir -p /ansible_config

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set correct permissions for SSH keys
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

ENV ANSIBLE_CONFIG=/ansible_config/ansible.cfg
ENV ANSIBLE_INVENTORY=/ansible_config/hosts


# Vim configuration - adding line numbers and syntax highlighting, backspace working as delete, invoke vim settings (newer) instaed of vi
RUN echo "set nocompatible\nset backspace=indent,eol,start\nset number\nsyntax on" > /root/.vimrc

# default ansible config file with most of the modules disabled
RUN ansible-config init --disabled -t all >/etc/ansible/ansible.cfg

RUN echo "source /tmp/ssh-agent-env" >> /root/.bashrc

CMD ["/bin/bash"]
