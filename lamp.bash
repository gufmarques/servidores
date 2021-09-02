#!/bin/bash
# ----------------------------------------------------------------------------
#
# Script de instalação de um WEBSERVER em sistemas operacionais Debian 9 e 10
#
# Autor Gustavo Marques - 2021
# Criado em 01 de setembro de 2021
# Atualizado em 02 de setembro de 2021
# Licença: GPL
# ----------------------------------------------------------------------------
# Variável da Data Inicial para calcular o tempo de execução do script 
HORAINICIAL=$(date +%T)
# Variável para saber se o usuario é root
USUARIO=$(id -u)
# variável que pega o nome da distribuiçao, poderia ser tb: uname -a | awk '{print $2}', mas a sáida sera em minúsculo (debian)
distro="$(cat /etc/issue | awk '{print $1}' | sed '/^$/d')";
# pega a versão da distro, se pôr f2 no cut pega a variação, ex.: 7.(2), 6.(5), 12.(10), ...
versao="$(cat /etc/issue | awk '{print $3}' | cut -d. -f1 | sed '/^$/d')";
# Variáveis de configuração do usuário root e senha do MySQL para acesso via console e do PhpMyAdmin
USER="root"
PASSWORD="toor"
AGAIN=$PASSWORD
#
# Variáveis de configuração e liberação da conexão remota para o usuário Root do MySQL
# opões do comando GRANT: grant (permissão), all (todos privilégios), on (em ou na | banco ou tabela), 
# *.* (todos os bancos/tabelas) to (para), user@'%' (usuário @ localhost), identified by (identificado 
# por - senha do usuário)
# opção do comando FLUSH: privileges (recarregar as permissões)
GRANTALL="GRANT ALL ON *.* TO $USER@'%' IDENTIFIED BY '$PASSWORD';"
FLUSH="FLUSH PRIVILEGES;"
GRANTALLPHPMYADMIN="GRANT ALL ON phpmyadmin.* TO $USER@'%' IDENTIFIED BY '$PASSWORD';"
#
# Variáveis de configuração do PhpMyAdmin
ADMINUSER=$USER
ADMIN_PASS=$PASSWORD
APP_PASSWORD=$PASSWORD
APP_PASS=$PASSWORD
WEBSERVER="apache2"
#
# ----------------------------------------------------------------------------
echo "################################################################"
echo "Iniciando Auto Configuração"
echo "################################################################"
echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n"

# só iniciará o processo de estiver logado como ROOT
if [ "$USUARIO" = "0" ] ; then
	echo "O usuário é Root, continuando com o script...";
else
	echo "Você precisa ser root.\nAbortar.";
	exit 0;
fi

# função para atualizar o sistema com o source.list atual
atualizar(){	
	apt-get update -y
	apt-get upgrade -y	
}

# função para alterar o sources.list
novalista(){
	# backup do sources.list
	cp /etc/apt/sources.list /etc/apt/bkp.sources.list	
	
	# sources.list pra Debian 9 stretch
	stretch="deb http://ftp.br.debian.org/debian stretch main contrib non-free
deb http://security.debian.org/ stretch/updates main contrib non-free
deb http://ftp.br.debian.org/debian/ stretch-updates main contrib non-free";

	# sources.list para Debian 10 buster
	buster="deb http://deb.debian.org/debian/ buster main non-free contrib
deb-src http://deb.debian.org/debian/ buster main non-free contrib

deb http://security.debian.org/debian-security buster/updates main contrib non-free
deb-src http://security.debian.org/debian-security buster/updates main contrib non-free

# buster-updates, previously known as 'volatile'
deb http://deb.debian.org/debian/ buster-updates main contrib non-free
deb-src http://deb.debian.org/debian/ buster-updates main contrib non-free

# buster-backports, previously on backports.debian.org
#deb http://deb.debian.org/debian/ buster-backports main contrib non-free
#deb-src http://deb.debian.org/debian/ buster-backports main contrib non-free";
		
	if [ "$versao" = "9" ]; then
		
		echo "$stretch" > /etc/apt/sources.list
		
	elif [ "$versao" = "10" ]; then
		
		echo "$buster" > /etc/apt/sources.list
			
	else		
		# nao faça nada
		echo "Versao incompativel, script aceita apenas versoes 9 e 10.";
			
	fi				
	
	# atualizando de novo, se houve novo source list, se não, continuará na mesma
	apt-get -y update
	apt-get -y upgrade
	apt-get -y autoremove
}

intervalo(){
sleep 5;
}

firmware(){
	apt-get install firmware-linux-nonfree -y;	
}

essenciais(){
echo "################################################################"
echo "Instalando pacotes essenciais"
apt -y install wget net-tools; 
echo "Pacotes essenciais instalado com sucesso"
echo "################################################################"
}

apache2(){
echo "################################################################"
echo "Instalando o Apache2"
apt -y install apache2; 
echo "Apache2 instalado com sucesso"
echo "################################################################"
}

mysql(){
echo "################################################################"
echo "Instalando o mariadb"
apt -y install mariadb-server;
echo "mariadb instalado com sucesso"
echo "################################################################"
mysql_secure_installation
echo "################################################################"
echo -e "Permitindo o Root do MySQL se autenticar remotamente, aguarde..."	
# opção do comando mysql: -u (user), -p (password) -e (execute)
mysql -u $USER -p$PASSWORD -e "$GRANTALL" 
mysql -u $USER -p$PASSWORD -e "$FLUSH" 
echo -e "Permissão alterada com sucesso!!!, continuando com o script...\n"
}

php(){
echo "################################################################"
echo "Instalando o PHP"
apt -y install php php-mysql libapache2-mod-php;
echo "PHP instalado com sucesso"
echo "################################################################"
}

phpmyadmin(){
echo "################################################################"
cd /tmp
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
unzip phpMyAdmin*;
rm -rf phpMyAdmin*.zip;
mv phpMyAdmin* /usr/share/phpmyadmin;
chown -R www-data:www-data /usr/share/phpmyadmin;

# Create the dababase.
mysql -u $USER -p$PASSWORD -e "DROP DATABASE IF EXISTS phpmyadmin;";
mysql -u $USER -p$PASSWORD -e "CREATE DATABASE phpmyadmin DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;";
mysql -u $USER -p$PASSWORD -e "$GRANTALLPHPMYADMIN";
mysql -u $USER -p$PASSWORD -e "$FLUSH";

defaultConfig="#phpMyAdmin default Apache configuration

Alias /phpmyadmin /usr/share/phpmyadmin
<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    <IfModule mod_php5.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
        php_value include_path .
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        php_admin_value mbstring.func_overload 0
    </IfModule>
    <IfModule mod_php.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>
        <FilesMatch ".+\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
        php_value include_path .
        php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
        php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        php_admin_value mbstring.func_overload 0
    </IfModule>
</Directory>
# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
    Require all denied
</Directory>";

echo "$defaultConfig" > /etc/apache2/conf-available/phpmyadmin.conf
mkdir -p /var/lib/phpmyadmin/tmp
chown www-data:www-data /var/lib/phpmyadmin/tmp
systemctl reload apache2
}

# função para instalar os aplicativos que dependerão de interação do usuário(para responder perguntas do Shell)
lamp9(){
echo "Instalando o Apache2"
apt-get -y install apache2; 
echo "Apache2 instalado com sucesso"
echo "################################################################"
echo "Instalando o mariadb"
apt-get -y install mariadb-server;
echo "mariadb instalado com sucesso"
echo "################################################################"
echo "Instalando o PHP"
apt-get -y install php php-fpm php-pdo php-gd php-mysqlnd php-mbstring php-common php-gettext php-curl php-cli;
echo "PHP instalado com sucesso"
echo "################################################################"
echo "Startando os serviços apache2 e mariadb"
service apache2 restart;
service mariadb restart;
echo "################################################################"
echo "Colocar os serviços pra subir no boot"
update-rc.d apache2 defaults;
update-rc.d mysql defaults;
echo "################################################################"
echo "Trocar senha do mysql"
read -p "Responda os questionamentos para trocar a senha do mysql ou CTRL+C para sair..."
mysql_secure_installation
echo "################################################################"
echo "Instalando o phpmyadmin"
echo "################################################################"
read -p "Marca a opção apache2 / sim / define uma senha e confirma ou CTRL+C para sair..."
apt-get -y install phpmyadmin;
echo "Startando o serviço apache2"
service apache2 restart;
service mariadb restart;
echo "################################################################"
echo "################################################################"
echo "#######Alterando privilégios do usuário phpmyadmin no phpmyadmin#######"
echo "################################################################"
echo "###################mysql -u root -p#########################"
echo "######GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost';#########"
echo "#####################exit###############################"
echo "####################service mariadb restart####################"
echo "#######Caso queira criar um novo usuário, execute o comando:#######"
echo "##CREATE USER 'seuUsuario'@'localhost' IDENTIFIED BY 'suaSenha';"	
}



# chama todas as funções
	if [ "$distro" = "Debian" ]; then
		
		atualizar
		intervalo
		novalista
		intervalo
		firmware
		intervalo
		essenciais
		intervalo
		apache2
		intervalo
		mysql
		
		if [ "$versao" = "9" ]; then
								
		elif [ "$versao" = "10" ]; then
		
			php
			intervalo
			phpmyadmin
			intervalo
		else		
			# nao faça nada
			echo "Versao incompativel, script aceita apenas versoes 9 e 10.";
			
		fi		
		
	else
		# deixará como está
		echo "Distribuicao incompativel, script aceita apenas Debian.";
		
	fi

# se tudo der certo
echo -e "Instalação do LAMP-SERVER feito com Sucesso!!!"
# script para calcular o tempo gasto
# opção do comando date: +%T (Time)
HORAFINAL=`date +%T`
# opção do comando date: -u (utc), -d (date), +%s (second since 1970)
HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
# opção do comando date: -u (utc), -d (date), 0 (string command), sec (force second), +%H (hour), %M (minute), %S (second), 
TEMPO=`date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S"`
# $0 (variável de ambiente do nome do comando)
echo -e "Tempo gasto para execução do script $0: $TEMPO"
# opção do comando date: + (format), %d (day), %m (month), %Y (year 1970), %H (hour 24), %M (minute 60)
echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n"
exit 0
