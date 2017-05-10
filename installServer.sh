#! /bin/bash

#####################################################################
# COMMAND LINE INPUT
#####################################################################
if [ -z "$1" ]; then
    echo "It was not specified server ip"
    exit 1 
fi
if [ -z "$2" ]; then
    echo "It was not specified database name"
    exit 1
fi
if [ -z "$3" ]; then
    echo "It was not specified postgres user name"
    exit 1
fi
if [ -z "$4" ]; then
    echo "It was not specified postgres user password"
    exit 1
fi
if [ -z "$5" ]; then
    echo "It was not specified linux user name"
    exit 1
fi
if [ -z "$6" ]; then
    echo "It was not specified django secret key"
    exit 1
fi

SERVER_IP=$1
DATABASE_NAME=$2
POSTGRES_USER=$3
POSTGRES_PASS=$4
LINUX_USER_NAME=$5
DJANGO_SECRET_KEY=$6

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
fi

PROJECT_PATH=/home/"$LINUX_USER_NAME"
PROJECT_DIR="$PROJECT_PATH"/"$REPOSITORY_NAME"

# virtual environment
VIRTUAL_ENV_NAME="myenv"
VIRTUAL_ENV_DIR="$PROJECT_DIR"/"$VIRTUAL_ENV_NAME"

#####################################################################
# CONFIGURATION
#####################################################################

clone_project=true
install_packages=false
postgresql_configuration=false
project_configuration=false
apache_configuration=false


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
    fi

    # move to installation folder
    cd "$INSTALLER_FOLDER"
fi

#####################################################################
# REQUIREMENTS
#####################################################################

if $install_packages; then

    apt-get update
    apt-get upgrade --yes

    # install dependencies

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
    sudo -H pip install -r requirements.txt

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
 
  # configure wsgi
  cd "$INSTALLER_FOLDER"
  python wsgiConfig.py "$PROJECT_DIR" "$REPOSITORY_NAME"

  SETTING_PATH="$PROJECT_DIR"/"$REPOSITORY_NAME"
  KEYS_PATH="$SETTING_PATH"/keys

  # set secret_key variable
  SECRET_KEY_FILE="$KEYS_PATH"/secret_key.py
  # change parameter
  echo "SECRET_KEY=\"""$DJANGO_SECRET_KEY""\"" > "$SECRET_KEY_FILE"

  DATABASE_CONFIG_TEMPLATE=./template_database.py
  DATABASE_CONFIG_FILE="$KEYS_PATH"/database.py
  cp "$DATABASE_CONFIG_TEMPLATE" "$DATABASE_CONFIG_FILE"
  # change parameter
  sed -i -e 's/<DATABASE>/'"$DATABASE_NAME"'/g' "$DATABASE_CONFIG_FILE"
  sed -i -e 's/<USER>/'"$POSTGRES_USER"'/g' "$DATABASE_CONFIG_FILE"
  sed -i -e 's/<PASSWORD>/'"$POSTGRES_PASS"'/g' "$DATABASE_CONFIG_FILE"

  # create folder used by loggers if not exist
  LOG_DIR="$PROJECT_DIR"/"$REPOSITORY_NAME"/logs
  sudo -u "$LINUX_USER_NAME" mkdir -p "$LOG_DIR"
  touch "$LOG_DIR"/file.log
  chmod 777 "$LOG_DIR"/file.log

  # add ip to allowed_hosts list
  sed -i -e 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = [u'"'$SERVER_IP'"']/g' "$SETTING_PATH"/settings.py

  # update database models and static files
  source "$VIRTUAL_ENV_DIR"/bin/activate
  python "$PROJECT_DIR"/manage.py migrate
  python "$PROJECT_DIR"/manage.py collectstatic

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
  configApache="fondef_viz_server.conf"

  python configApache.py "$PROJECT_PATH" "$REPOSITORY_NAME" "$VIRTUAL_ENV_NAME" "$configApache"
  a2dissite 000-default.conf
  a2ensite "$configApache"

  sudo service apache2 restart

  echo ----
  echo ----
  echo "Apache configuration ready"
  echo ----
  echo ----
fi

cd "$INSTALLER_FOLDER"

echo "Installation ready."
echo "To check that its all ok, enter to $SERVER_IP/admin"

