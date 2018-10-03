import sys
import os

def getConfigFileHTTP(projectPath, projectName, virtualEnvName):
    projectDir = "{}/{}".format(projectPath, projectName)
    return '''
    WSGIApplicationGroup %{GLOBAL}
    WSGIDaemonProcess ''' + projectName + ''' python-path=''' + projectDir + ''' python-home=''' + projectDir + '''/''' + virtualEnvName + ''' processes=3 threads=100 display-name='srvr-fondef' user='server' group='server'

    <VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com

        #ServerAdmin webmaster@localhost
        #DocumentRoot /var/www/html

        Alias /static ''' + projectDir + '''/static
        <Directory ''' + projectDir + '''/static>
                Require all granted
        </Directory>

        <Directory ''' + projectDir + '''/''' + projectName + '''>
                <Files wsgi.py>
                      Require all granted
                </Files>
        </Directory>

        LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so

        WSGIProcessGroup ''' + projectName + '''
        WSGIScriptAlias / ''' + projectDir + '''/''' + projectName + '''/wsgi.py

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log reqtime

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
    </VirtualHost>
    

    <IfModule mod_ssl.c>
        <VirtualHost *:443>
            # como es usado por un proxy, necesitamos conectarnos a traves de la ip
            ServerName adatrap.cl
            ServerAlias www.adatrap.cl

            SSLCertificateFile /etc/letsencrypt/live/adatrap.cl/cert.pem
            SSLCertificateKeyFile /etc/letsencrypt/live/adatrap.cl/privkey.pem
            Include /etc/letsencrypt/options-ssl-apache.conf
            SSLCertificateChainFile /etc/letsencrypt/live/adatrap.cl/chain.pem

            Alias /static ''' + projectDir + '''/static
            <Directory ''' + projectDir + '''/static>
                Require all granted
            </Directory>

            <Directory ''' + projectDir + '''/''' + projectName + '''>
                <Files wsgi.py>
                      Require all granted
                </Files>
            </Directory>

            Alias /downloads /es2/downloads
            <Directory /es2/downloads>
                Require all granted
            <Directory>
            
            LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so

            WSGIProcessGroup ''' + projectName + '''
            WSGIScriptAlias / ''' + projectDir + '''/''' + projectName + '''/wsgi.py

            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log reqtime
       </VirtualHost>   
    </IfModule>'''

def processApacheConfigFile(projectPath, projectName, virtualEnvName, apacheFileName):

    configFile = getConfigFileHTTP(projectPath, projectName, virtualEnvName)

    #Writte the file to destination
    PATH = '/etc/apache2/sites-available/'
    pathFile = "{}{}".format(PATH, apacheFileName)

    FILE = open(pathFile, 'w')
    for line in configFile:
        FILE.write(line)
    FILE.close()

if __name__ == "__main__":
    if len(sys.argv) < 4:
        pass
    else:
        projectPath = sys.argv[1]
        projectName = sys.argv[2]
        virtualEnvName = sys.argv[3]
        apacheFileName = sys.argv[4]
        processApacheConfigFile(projectPath, projectName, virtualEnvName, apacheFileName)
