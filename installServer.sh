#! /bin/bash

#####################################################################
# CONFIGURATION
#####################################################################

clone_project=false
install_packages=false
postgresql_configuration=false
project_configuration=false
apache_configuration=true
django_worker_config=false

#####################################################################
# COMMAND LINE INPUT
#####################################################################
if [ -z "$1" ]; then
    read -p "User name was not provided, would you like to use 'server' as user name?(y/n)" -n 1
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
	echo "using user name 'server'"
        LINUX_USER_NAME="server"
    else
	echo "You have to provided an user name"
        exit 1
    fi
else
    LINUX_USER_NAME=$1
fi

# name of github repository
REPOSITORY_NAME="fondefVizServer"
GITHUB_URL="https://github.com/SmartcitySantiagoChile/fondefVizServer.git"

#####################################################################
# SETUP
#####################################################################

SCRIPT="$(readlink "$0")"
INSTALLER_FOLDER="$(dirname "$SCRIPT")"
if [ ! -d "$INSTALLER_FOLDER" ]; then
    echo "failed to retrieve the installer folder path"
    exit 1
fi
unset SCRIPT

# move to installation folder
cd "$INSTALLER_FOLDER"

#####################################################################
# USER CONFIGURATION
#####################################################################

# stores the current path
if id "$LINUX_USER_NAME" >/dev/null 2>&1; then
    echo "User $LINUX_USER_NAME already exists.. skipping"
else
    echo "User $LINUX_USER_NAME does not exists.. CREATING!"
    adduser "$LINUX_USER_NAME"
    adduser "$LINUX_USER_NAME" sudo
fi

PROJECT_PATH=/home/"$LINUX_USER_NAME"
PROJECT_DIR="$PROJECT_PATH"/"$REPOSITORY_NAME"

# virtual environment
VIRTUAL_ENV_NAME="myenv"
VIRTUAL_ENV_DIR="$PROJECT_DIR"/"$VIRTUAL_ENV_NAME"

#####################################################################
# CLONE PROJECT
#####################################################################

if $clone_project; then

    apt-get install --yes git

    cd "$PROJECT_PATH"

    # clone project from git
    echo ""
    echo "----"
    echo "Clone project from gitHub"
    echo "----"
    echo ""
  
    DO_CLONE=true
    if [ -d "$REPOSITORY_NAME" ]; then
        echo ""
        echo "$REPOSITORY_NAME repository already exists."
        read -p "Do you want to remove it and clone it again? [Y/n]: " -n 1 -r
        echo # (optional) move to a new line
        DO_CLONE=false
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo "Removing repository '$REPOSITORY_NAME' at: $(pwd)"
            rm -rf "$REPOSITORY_NAME"
            DO_CLONE=true
        fi
    fi

    if "$DO_CLONE" ; then
        git clone "$GITHUB_URL"
        chown -R "$LINUX_USER_NAME":"$LINUX_USER_NAME" "$PROJECT_PATH"
	git submodule init
	git submodule update
    fi

    # move to installation folder
    cd "$INSTALLER_FOLDER"
fi

#####################################################################
# REQUIREMENTS
#####################################################################

if $install_packages; then

    # ssl 
    apt-get update
    apt-get --yes install software-properties-common
    sudo add-apt-repository ppa:certbot/certbot -y

    apt-get update
    apt-get upgrade --yes

    # install dependencies
    apt-get --yes install python-certbot-apache

    # install postgres
    apt-get --yes install postgresql postgresql-contrib 
    # install apache
    apt-get install --yes apache2 libapache2-mod-wsgi
    # install python and pip
    apt-get --yes install python-pip python-dev libpq-dev
    # upgrade pip
    sudo -H pip install -U pip
    # install npm
    apt-get --yes install nodejs
    apt-get --yes install npm
    ln -s /usr/bin/nodejs /usr/bin/node
    # install bower
    npm install -g bower

    sudo -H pip install virtualenv
    cd "$PROJECT_DIR"
    # create virtual env
    sudo -u "$LINUX_USER_NAME" virtualenv "$VIRTUAL_ENV_NAME"
    # activate virtualenv
    source "$VIRTUAL_ENV_DIR"/bin/activate

    # install bower requirements
    bower install --allow-root

    # install python requirements
    pip install -r requirements.txt

    # move to installation folder
    cd "$INSTALLER_FOLDER"
fi

#####################################################################
# POSTGRESQL
#####################################################################
if $postgresql_configuration; then
  echo ----
  echo ----
  echo "Postgresql"
  echo ----
  echo ----

  echo "Please enter database name:"
  while [ "$DATABASE_NAME" == "" ]
  do
    read -r DATABASE_NAME
  done

  echo "Please enter database user name:"
  while [ "$DATABASE_USER" == "" ]
  do
    read -r POSTGRES_USER
  done

  echo "Please enter database user password:"
  while [ "$DATABASE_PASS" == "" ] 
  do
    read -r POSTGRES_PASS
  done

  CREATE_DATABASE=true
  DATABASE_EXISTS=$(sudo -Hiu postgres psql -lqt | cut -d \| -f 1 | grep -w "$DATABASE_NAME")
  if [ "$DATABASE_EXISTS" ]; then
      echo ""
      echo "The database $DATABASE_NAME already exists."
      read -p "Do you want to remove it and create it again? [Y/n]: " -n 1 -r
      echo # (optional) move to a new line
      CREATE_DATABASE=false
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo "Removing database $DATABASE_NAME..."
        sudo -Hiu postgres psql -c "DROP DATABASE $DATABASE_NAME;"
        CREATE_DATABASE=true
      fi
  fi
  
  if "$CREATE_DATABASE" ; then
      # change config of psql
      cd "$INSTALLER_FOLDER"
  
      # create user and database
      POSTGRES_TEMPLATE_FILE=./template_postgresqlConfig.sql
      POSTGRES_FINAL_FILE=./postgresqlConfig.sql
      # copy the template
      cp "$POSTGRES_TEMPLATE_FILE" "$POSTGRES_FINAL_FILE"
      
      # change parameters
      sed -i -e 's/<DATABASE>/'"$DATABASE_NAME"'/g' "$POSTGRES_FINAL_FILE"
      sed -i -e 's/<USER>/'"$POSTGRES_USER"'/g' "$POSTGRES_FINAL_FILE"
      sed -i -e 's/<PASSWORD>/'"$POSTGRES_PASS"'/g' "$POSTGRES_FINAL_FILE"
  
      # postgres user has to be owner of the file and folder that contain the file
      CURRENT_OWNER=$(stat -c '%U' .)
      # change owner to let postgres user exec file
      chown postgres:postgres "$INSTALLER_FOLDER"/postgresqlConfig.sql
      chown postgres:postgres "$INSTALLER_FOLDER"
      sudo -u postgres psql -f "$POSTGRES_FINAL_FILE"
      rm "$POSTGRES_FINAL_FILE"
      chown "$CURRENT_OWNER":"$CURRENT_OWNER" "$INSTALLER_FOLDER"
  fi

  echo ----
  echo ----
  echo "Postgresql ready"
  echo ----
  echo ----
fi


#####################################################################
# SETUP DJANGO APP
#####################################################################
if $project_configuration; then
  echo ----
  echo ----
  echo "Project configuration"
  echo ----
  echo ----

  echo "We need an IP address to configure ALLOWED_HOSTS in django:"
  while [ "$SERVER_IP" == "" ]
  do
    read -r SERVER_IP
  done

  echo "You need to provide a path where it will be putted downloaded files:"
  while [ "$DOWNLOAD_PATH" == "" ]
  do
    read -r DOWNLOAD_PATH
  done
 
  # configure wsgi
  cd "$INSTALLER_FOLDER"

  SETTING_PATH="$PROJECT_DIR"/"$REPOSITORY_NAME"

  CONFIG_FILE_TEMPLATE=.env_template
  CONFIG_FILE="$PROJECT_DIR"/.env
  cp "$CONFIG_FILE_TEMPLATE" "$CONFIG_FILE"
  # change parameter
  sed -i -e 's/DB_NAME=/DB_NAME='"$DATABASE_NAME"'/g' "$CONFIG_FILE"
  sed -i -e 's/DB_USER=/DB_USER='"$POSTGRES_USER"'/g' "$CONFIG_FILE"
  sed -i -e 's/DB_PASS=/DB_PASS='"$POSTGRES_PASS"'/g' "$CONFIG_FILE"
  sed -i -e 's/DOWNLOAD_PATH=/DOWNLOAD_PATH='"$DOWNLOAD_PATH"'/g' "$CONFIG_FILE"

  # create folder used by loggers if not exist
  LOG_DIR="$PROJECT_DIR"/"$REPOSITORY_NAME"/logs
  sudo -u "$LINUX_USER_NAME" mkdir -p "$LOG_DIR"
  touch "$LOG_DIR"/file.log
  chmod 700 "$LOG_DIR"/file.log

  # add ip to allowed_hosts list
  sed -i -e 's/ALLOWED_HOSTS=/ALLOWED_HOSTS='"'$SERVER_IP'"'/g' "$CONFIG_FILE"

  # update database models and static files
  source "$VIRTUAL_ENV_DIR"/bin/activate
  python "$PROJECT_DIR"/manage.py migrate
  python "$PROJECT_DIR"/manage.py collectstatic
  python "$PROJECT_DIR"/manage.py loaddata datasource 
  python "$PROJECT_DIR"/manage.py loaddata communes daytypes halfhours operators timeperiods transportmodes 

  echo ----
  echo ----
  echo "Project configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# APACHE CONFIGURATION
#####################################################################

if $apache_configuration; then
  echo ----
  echo ----
  echo "Apache configuration"
  echo ----
  echo ----
  # configure apache 2.4

  cd "$INSTALLER_FOLDER"

  echo "You need to provide a path where it will be putted downloaded files:"
  while [ "$DOWNLOAD_PATH" == "" ]
  do
    read -r DOWNLOAD_PATH
  done

  CONFIG_APACHE="fondef_viz_server.conf"

  python configApache.py "$PROJECT_PATH" "$REPOSITORY_NAME" "$VIRTUAL_ENV_NAME" "$CONFIG_APACHE" "$LINUX_USER_NAME" "$DOWNLOAD_PATH"
  a2dissite 000-default.conf
  a2ensite "$CONFIG_APACHE"

  # enable modules ssl and wsgi
  a2enmod ssl
  a2enmod wsgi

  # add reqtime to apache2.conf // response time in apache log
  APACHE_CONFIG_FILE="/etc/apache2/apache2.conf"
  if grep -Fq "reqtime" "$APACHE_CONFIG_FILE"
  then
    echo "reqtime found in file, we do not do anything"
  else
    echo "reqtime does not exist in file"
    LOG_FORMAT="LogFormat \"%h %l %u %t \\\"%r\\\" %>s %O \\\"%{Referer}i\\\" \\\"%{User-Agent}i\\\" %D\" reqtime"
    echo "$LOG_FORMAT" >> "$APACHE_CONFIG_FILE"
  fi

  sudo service apache2 restart

  # install ssl certificates
  certbot --apache certonly

  echo "REMEMBER: YOU HAVE TO UPDATE SSL CERTIFICATES EVERY THREE MONTHS. YOU CAN USE 'certbot renew' IN CRON"

  echo ----
  echo ----
  echo "Apache configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# DJANGO-RQ WORKER SERVICE CONFIGURATION
#####################################################################
if $django_worker_config; then
  echo ----
  echo ----
  echo "Django-rq worker service configuration"
  echo ----
  echo ----

  cd "$INSTALLER_FOLDER"
  echo "$PROJECT_DIR"
  # Creates the service unit file and the service script
  sudo python rqWorkerConfig.py "$PROJECT_DIR" "$VIRTUAL_ENV_NAME"

  # Makes the service script executable
  cd "$PROJECT_DIR/rqworkers"
  sudo chmod 775 djangoRqWorkers.sh
  cd "$INSTALLER_FOLDER"

  # Enables and restarts the service
  sudo systemctl enable django-worker
  sudo systemctl daemon-reload
  sudo systemctl restart django-worker

  echo ----
  echo ----
  echo "Django-rq worker service configuration ready"
  echo ----
  echo ----
fi

cd "$INSTALLER_FOLDER"

echo "script finished"
echo "REMEMBER TO FILL .env FILE WITH VALUES"

