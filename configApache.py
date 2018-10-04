import sys
import os

def get_config_http_file(project_path, project_name, virtual_env_name, linux_user_name, download_path):
    project_dir = '{}/{}'.format(project_path, project_name)
    return '''

LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so
LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so

WSGIApplicationGroup %{GLOBAL}
WSGIDaemonProcess ''' + project_name + ''' python-path=''' + project_dir + ''' python-home=''' + project_dir + '''/''' + virtual_env_name + ''' processes=3 threads=100 display-name='srvr-adatrap' user="''' + linux_user_name + '''" group="''' + linux_user_name + '''"

<VirtualHost *:80>
    ServerName adatrap.cl
    ServerAlias www.adatrap.cl

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log reqtime

    Redirect permanent / https://www.adatrap.cl/
</VirtualHost>
    
<VirtualHost *:443>
    ServerName adatrap.cl
    ServerAlias www.adatrap.cl

    SSLCertificateFile /etc/letsencrypt/live/adatrap.cl/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/adatrap.cl/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateChainFile /etc/letsencrypt/live/adatrap.cl/chain.pem

    Alias /static ''' + project_dir + '''/static
    <Directory ''' + project_dir + '''/static>
        Require all granted
    </Directory>

    <Directory ''' + project_dir + '''/''' + project_name + '''>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>

    Alias /downloads ''' + download_path + '''
    <Directory ''' + download_path + '''>
        Require all granted
    </Directory>
            
    WSGIProcessGroup ''' + project_name + '''
    WSGIScriptAlias / ''' + project_dir + '''/''' + project_name + '''/wsgi.py

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log reqtime
</VirtualHost>'''

def process_apache_config_file(project_path, project_name, virtual_env_name, apache_file_name, linux_user_name, download_path):

    config_file = get_config_http_file(project_path, project_name, virtual_env_name, linux_user_name, download_path)

    #Writte the file to destination
    path = '/etc/apache2/sites-available/'
    path_file = "{}{}".format(path, apache_file_name)

    FILE = open(path_file, 'w')
    for line in config_file:
        FILE.write(line)
    FILE.close()

if __name__ == "__main__":
    if len(sys.argv) < 7:
        raise ValueError('You need to provide more parameters')
    else:
        project_path = sys.argv[1]
        project_name = sys.argv[2]
        virtual_env_name = sys.argv[3]
        apache_file_name = sys.argv[4]
        linux_user_name = sys.argv[5]
        download_path = sys.argv[6]
        process_apache_config_file(project_path, project_name, virtual_env_name, apache_file_name, linux_user_name, download_path)
