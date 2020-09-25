# ansible-raspbian

[![Ansible Role](https://img.shields.io/ansible/role/30388.svg)](https://galaxy.ansible.com/hannseman/raspbian)
[![Travis (.org)](https://img.shields.io/travis/hannseman/ansible-raspbian.svg)](https://travis-ci.com/hannseman/ansible-raspbian)

This role will setup a secure basic Raspbian environment with sensible defaults.

### It will:

 * Install specified system packages.
 * Configure hostname.
 * Configure locale.
 * Mount tmpfs on write-intensive directories to increase the lifespan of SD-card.
 * Change the password on default user.
 * Set the default editor.
 * Setup a secure SSH configuration.
 * Configure UFW.
 * Configure /boot/config.txt.
 * Run raspi-config.
 * Configure Postfix to send email through an SMTP relay.
 * Enable unattended-upgrades.
 * Install Fail2ban.
 * Configure Logwatch to send weekly reports.

### It will not:

 * Update system packages.
 * Run `apt-get update`. Please do this in a pre_task. See [Example Playbook](#example-playbook).
 * Install security patches but unattended-upgrades should take care of that.

## Setup
* Install python requirements by running `pip install -r requirements.txt`.
* Install sshpass by running `sudo apt-get install sshpass`.
* Flash SD-card with [Raspbian Stretch Lite](https://www.raspberrypi.org/documentation/installation/installing-images/mac.md).
* Add empty file named `ssh` in boot-partition of the flashed SD-card.
* Optional: To enable wifi place a file called `wpa_supplicant.conf` in the boot-partition of the flashed SD-card with the following content:
```
network={
        ssid="your ssid"
        psk="your password"
}
```
* Run playbook.


## Inventory

[sshpass](https://linux.die.net/man/1/sshpass) is required to make the first Ansible run
with the default password `raspberry`. Password authentication over SSH will then be disabled in
preference of public key authentication with keys specified in `ssh_public_keys`.
Your inventory should contain the following:

```ini
[all:vars]
ansible_connection=ssh
ansible_user=pi
ansible_ssh_pass=raspberry
```

## Variables

```yaml
# Sets the system hostname
system_hostname: "raspberrypi"
# The system password for ansible_ssh_user (should configured as pi).
# NOTE: Should be changed to something secure.
system_ssh_user_password: "raspberry"
# The password salt to use.
# NOTE: Should be changed to something secure and random.
system_ssh_user_salt: "salt"
# The system locale
system_locale: "en_US.UTF-8"
# The system timezone
system_timezone: "Europe/Stockholm"
# List dictionaries of desired tmpfs mounts.
system_tmpfs_mounts:
  - { src: "/run", size: "10%", options: "nodev,noexec,nosuid" }
  - { src: "/tmp", size: "10%", options: "nodev,nosuid" }
  - { src: "/var/log", size: "10%", options: "nodev,noexec,nosuid" }
# apt-get installs listed packages
system_packages: []
# Path to default editor
system_default_editor_path: "/usr/bin/vi"

# Logwatch cache directory
logwatch_tmp_dir: /var/cache/logwatch
# Email which receives Logwatch reports
logwatch_mailto: "root"
# Logwatch report detail level
logwatch_detail: "Low"
# How often to receive Logwatch report, can be set to weekly and daily
logwatch_interval: "weekly"

postfix_hostname: "{{ ansible_hostname }}"
postfix_mailname: "{{ ansible_hostname }}"
postfix_mydestination:
  - "{{ postfix_hostname }}"
  - localdomain
  - localhost
  - localhost.localdomain
postfix_relayhost: smtp.gmail.com
postfix_relayhost_port: 587
# Required field, set this to your Gmail-address
postfix_sasl_user:
# Required field, set this to your Gmail password
postfix_sasl_password:
postfix_smtp_tls_cafile: /etc/ssl/certs/ca-certificates.crt

# Updates /boot/config.txt with `{{ key }}: {{ value }}`
rpi_boot_config: {}
# run raspi-config -noint do_{{ key }} {{ value }]. Options: https://github.com/raspberrypi-ui/rc_gui/blob/master/src/rc_gui.c#L23-L70
rpi_cmdline_config: {}

ssh_sshd_config: "/etc/ssh/sshd_config"
# Required field, list of ssh public keys to update ~/.authorized_keys.
# Note: One of these keys needs to be one that Ansible is using.
ssh_public_keys: []
# String to present when connecting to host over ssh
ssh_banner:

# UFW rules should always allow SSH to keep Ansible functioning
ufw_rules:
  - { rule: "allow", port: "22", proto: "tcp" }
# Configures if igmp traffic should be allowed
ufw_allow_igmp: false

# Recipient of unattended-upgrades report
unattended_upgrades_email_address: root
# Should we reboot when /var/run/reboot-required is found?
unattended_upgrades_auto_reboot: false

# Internal variable used when running tests - should not be used.
ansible_raspbian_testing: false
```

## Example Playbook
```yaml
- hosts: servers
  become: true
  pre_tasks:
    - name: update apt cache
      apt:
        cache_valid_time: 600
  roles:
    - role: hannseman.raspbian
  vars:
    system_packages:
      - apt-transport-https
      - vim
    system_default_editor_path: "/usr/bin/vim.basic"
    system_ssh_user_password: hunter2
    system_ssh_user_salt: pepper
    postfix_sasl_user: root@example.com
    postfix_sasl_password: hunter2

    ssh_public_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXTGInmtpoG9rYmT/3DpL+0o/sH2shys+NwJLo8NnCj
```
