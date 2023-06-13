<VirtualHost *:{{APP_DEFAULT_PORT}}>
    ServerAlias {{APP_DOMAIN}}
    DocumentRoot {{DOCUMENT_ROOT}}
    AcceptPathInfo On
    <Directory />
        AcceptPathInfo On
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /dev/stderr
    CustomLog /dev/stdout combined
</VirtualHost>

# setting for h5
Alias /h5 "/apps/zentao/h5"
<Directory "/apps/zentao/h5">
  Options FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>
