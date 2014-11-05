ansible-ubuntu
==============

Fish script and Ansible playbook for automating a fresh install of an Ubuntu server. Tested on 14.04 and 14.10 on Digital Ocean.

Usage instructions
==================

Firstly, install Ansible. I found some nice instructions [here](https://devopsu.com/guides/ansible-mac-osx.html).

When booting up a server, please indicate that you wish to connect by public key, and supply one. The rest of the instructions will assume that you can already authenticate by public key.

Else, you can use `ssh-copy-id` to copy a generated public key to the server. This can be slightly complicated/annoying (making sure that your permissions to your `.ssh` folder and keys are restricted):

    ssh-keygen -t rsa -f "key filename"
    ssh-copy-id -i "~/.ssh/[key filename]" [user]@[server]

Google for more information.

## Options

Moving on, the Ansible playbook requires you to set some options before it can be run.

#### `hosts.ini`

After booting up your servers, paste your server names/IPs into `hosts.ini`. Start each server on a new line (and of course delete my lorem ipsum servers).

The rest of the options below are found in `bootstrap.yml`.

#### `ubuntu-release`

Default: `utopic`

Can be changed: yes

Specify the codename of your Ubuntu release. This will be required for the script to download the appropriate `unattended-packages` repo.

#### `deploy_user`

Default: deploy

Can be changed: yes, recommended

Specify the login name of your deploy user.

#### `key`

Default: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

Can be changed: yes, recommended

Specifies the location of the public key you want to install on the server for authentication.

#### `root_password`, `deploy_password`

Default: No default

Can be changed: MUST CHANGE (read below)

### Hashing our passwords

Firstly, Ansible requires passwords to be hashed, so let's generate some on our local machine.

Ubuntu's crypt function allows us to specify which encryption algorithm to use. In this instance, we will choose SHA-512. See documentation on crypt() [here](http://man7.org/linux/man-pages/man3/crypt.3.html).

On Mac OS X, its crypt function only supports DES, which is insecure, so download the passlib library from pip or easy_install:

    pip install passlib

Then, run the following Python script in Terminal. Using Python's `getpass()` function, it will prompt you for the password you want to set, then generate a SHA-512 hash using a randomly-generated salt, with 5000 rounds. 5000 rounds was chosen specifically to match with Linux's `crypt()` implementation, which appears to use 5000 rounds as a default.

    echo "from passlib.hash import sha512_crypt; import getpass; print (sha512_crypt.encrypt(getpass.getpass(), rounds=5000))" | python -

The script should print out something that resembles the following:

    $6$[random_string_of_characters_which_is_your_salt]$[hashed_output]

Note: If you're using SHA-256, it will start with `$5` instead.

Repeat the above twice to generate passwords for both root and your deploy user, then copy and paste it into the appropriate fields in the Ansible playbook. Remember to store your passwords securely (1Password, or write it down on a post-it and stick it on the side of your CPU (just kidding)).

#### `install_packages`

Default: `[vim,fail2ban]`

Can be changed: yes

Specify the name of packages you want to install from `apt-get`.

#### `new_ssh_port`

Default: 22

Can be changed: yes, recommended

Specify the new SSH port of your server.

#### `allowed_ports`

Default: 

    ssh:
        port: {{ new_ssh_port }}
        protocol: tcp


Can be changed: yes

Specify the ports/protocol you want to allow in your firewall (ufw). If you're setting up a web server, after setup you can open up port `80` (and any other ports you need) by running the following command:

    sudo ufw allow 80/tcp

## Epilogue

### Logging On

After this is done, you can log onto your server with the following command:

    ssh  [your_deploy_username]@[server] -p [your_ssh_port] -i [your_key_location]

Note: If your SSH port is 22 (unchanged), the `-p [your_ssh_port]` portion can be omitted. Likewise, if your key location is unchanged, the `-i [your_key_location]` can be omitted.

This is a weird thing, but it seems that you need to run bash manually after logging in for the first time. Just type `bash` in the command, and you should see your current username@server prepended to your `$` prompt. Also, the server may make some noise about needing to configure your locale and/or needing to reboot. Proceed accordingly.

### SSH config file

To save some keystrokes, you can configure a `config` file in your `.ssh` folder:

1. If it doesn't already exist, create a file in your `.ssh` folder called `config` (note the absence of any file extension).

2. Append the following to the file:

        Host [convenient_shortcut]
            HostName [server]
            Port [your_ssh_port]
            User [your_deploy_username]
            IdentityFile [your_key_location]

Now, from here on, you can simply SSH in by typing the command `ssh [convenient_shortcut]`.

### Configure fail2ban

You can go on to configure fail2ban's options to your liking, for example setting up a mail server to email regular intrusion attempts to you. Google for more information.

### Troubleshooting

If the Ansible playbook fails at any point, feel free to tweak the options or do some other form of troubleshooting and run it again. The script is idempotent (can be run over and over) as long as it doesn't reach the last step of disallowing root SSH access. If you wish to configure the Ansible playbook, make sure that disallowing root SSH access remains the last step.

#### Cannot SSH in

if the script is able to run `ssh-keyscan` successfully but fails when Ansible is trying to SSH in, try running just the Ansible command with verbose output:

    ansible-playbook -i hosts.ini bootstrap.yml --user root -vvvv

If it's nagging at you about your permissions being too open, `chmod` your folder and keys accordingly. I suggest `600` permissions for your keys and either `700` or `755` for your `.ssh` folder.
    
    chmod 600 id_rsa.pub

Otherwise, drop me a note and I'll see if I can help.

## TODO

- Create a bash version of the script
- Variants of this playbook that set up Mosh and/or fish
- Test on EC2
- Integrate with DO and EC2 APIs