# Overview

This repository mantains the code for deploying OsirisWebPlatform server on a linux machine, which means:
- Step 1: linux user creation
- Step 2: dependencies installation
- Step 3: postgresql configuration
- Step 4: clone and setup of the django app
- Step 5: apache configuration


--- 

# Prerequisites for server


## Linux Machine with Ubuntu 16.04

This has been tested on Ubuntu 16.04 machines.


## Superuser privileges

The installation script requires sudo access.


## Installer folder

`installServer.sh` script will use some commands with postgres user, so put installer folder under `/root` path is not a good idea. We recommend to use `/tmp` path.

---

# DEPLOYMENT


## Clone installer project

Move to `/tmp` directory
```bash
$ cd /tmp
```
Then type:
```bash
# clone directly on the target machine
$ git clone https://github.com/SmartcitySantiagoChile/fondefVizInstaller
```


## Understanding the installer

You need the following information:
- `<SERVER_PUBLIC_IP>`: This server public IP, used in apache configuration file
- `<DATABASE_NAME>`: Name of the new database
- `<POSGRES_USER>`: Name of the new postgres user
- `<POSTGRES_USER_PASS>`: Postgres user's password
- `<LINUX_USER_NAME>`: Linux user name used to choose the folder where web app project will be located (default: `/home/<LINUX_USER_NAME>`)
- `<DJANGO_SECRET_KEY>`: The django app needs a secret key, you can generate a new one [here](http://www.miniwebtool.com/django-secret-key-generator/). It's very common that secret key contains some special character, so you need to put the code between double quote (`'`).


It is highly recommended to read the script before running it and ALSO EXECUTTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on `installServer.sh` to select which steps you want to run. The recommended way is to deactivate all steps and run them separately. 

Inside `installServert.sh` you will discover 5 steps:
1. Clone project: clone django server project
2. Install packages: set virtualenv and install project dependencies
3. Postgresql configuration: create database and database user
4. Project configuration: Connect database with django project
5. Apache configuration: set wsgi

## Known Problems

### bower 

Bower manage javascript libraries used by visualization app but doesn't let you use it with sudo priviliges so it's probably you won't see a beatiful web page at the end of the process. To fix this problem you have to go `<path_to_project>` and run `bower install` with owner of directory where the project is.


## Running the installer

Go to the installation folder and execute the next command line.

**WARNING: PLEASE, do not call this script with like `./installServer.sh`**.

```bash
# run with sudo
$ sudo bash installServer.sh <SERVER_PUBLIC_IP> <DATABASE_NAME> <POSTGRES_USER> <POSTGRES_USER_PASS> <LINUX_USER_NAME> "<DJANGO_SECRET_KEY>"
```

When the script ends, you will need to append this machine IP address to `ALLOWED_HOSTS` django variable on the `settings.py` server file.

## Setting up apache

Finally, restart the apache server:
```bash
$ sudo service apache2 restart
```

## Create super user

To log in on web application you have to create a super user in django framework. You have to go `<path_to_project>` and run the next command ([createsuperuser](https://docs.djangoproject.com/en/1.10/ref/django-admin/#createsuperuser)).
```bash
$ python manage.py createsuperuser
```
With this new user you can create others through django admin web page (`<SERVER_IP>/admin`).


# The ends

After run everything before you are ready to share the web site :-).

