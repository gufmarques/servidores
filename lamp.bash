#!/bin/bash
# ----------------------------------------------------------------------------
#
# Script de instalação de um WEBSERVER em sistemas operacionais Debian 9
#
# Autor Gustavo Marques - 2021
# Atualizado em 01 de setembro de 2021
# Licença: GPL
# ----------------------------------------------------------------------------
# Variável da Data Inicial para calcular o tempo de execução do script 
# opção do comando date: +%T (Time)
HORAINICIAL=$(date +%T)
#
echo "################################################################"
echo "Iniciando Auto Configuração"
echo "################################################################"
echo -e "Início do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n"

# só iniciará o processo de estiver logado como ROOT
if [ "$USER" = "root" ] ; then
	echo "O usuário é Root, continuando com o script...";
else
	echo "Você precisa ser root.\nAbortar.";
	exit 0;
fi

# função para atualizar o sources.list
atualizar(){
	# com opção menos -y caso precise de interação
	apt-get update -y
	apt-get upgrade -y
	apt-get update -y
}

# função para alterar o sources.list
novalista(){

	# backup do sources.list
	cp /etc/apt/sources.list /etc/apt/bkp.sources.list
	
	# variável que pega o nome da distribuiçao, poderia ser tb: uname -a | awk '{print $2}', mas a sáida sera em minúsculo (debian)
	distro="$(cat /etc/issue | awk '{print $1}' | sed '/^$/d')";
	
	# pega a versão da distro, se pôr f2 no cut pega a variação, ex.: 7.(2), 6.(5), 12.(10), ...
	versao="$(cat /etc/issue | awk '{print $3}' | cut -d. -f1 | sed '/^$/d')";
	
	# sources.list pra Debian Squeeze
	stretch="deb http://ftp.br.debian.org/debian stretch main contrib non-free
deb http://security.debian.org/ stretch/updates main contrib non-free
deb http://ftp.br.debian.org/debian/ stretch-updates main contrib non-free";

	# sources.list para Debian Wheezy
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
	
	# sequencia de if, elif e else que determinará que sources.list será preenchido	
	if [ "$distro" = "Debian" ]; then
	
		if [ "$versao" = "9" ]; then
		
			echo "$stretch" > /etc/apt/sources.list
		# MODIFICADO deste item, tava como $distro, alterei pra $versao
		elif [ "$versao" = "10" ]; then
		
			echo "$buster" > /etc/apt/sources.list
			
		else		
			# nao faça nada
			echo
			
		fi		
		
	else
		# deixará como está
		echo
		
	fi
	
	# atualizando de novo, se houve novo source list, se não, continuará na mesma
	apt-get -y update
	apt-get -y upgrade
}

padroes(){

	# variável que pega o nome da distribuiçao, poderia ser tb: uname -a | awk '{print $2}', mas a sáida sera em minúsculo (debian)
	distro="$(cat /etc/issue | awk '{print $1}' | sed '/^$/d')";

	# se a distro for Debian, instalará os drives não-livres, se não, não instalará
	[ "$distro" = "Debian" ] && apt-get install firmware-linux-nonfree -y || echo "";
	
	# instalando Aplicativos para Usuários e Desenvolvedores
	
	
	
	
	
	
	
	
}

# função para instalar os aplicativos que dependerão de interação do usuário(para responder perguntas do Shell)
interativos(){
	
	
	echo "Instalando o Apache2"
apt-get -y install apache2; 
echo "Apache2 realizado com sucesso"
echo "################################################################"
echo "Instalando o mariadb"
apt-get -y install mariadb-server;
echo "mariadb realizado com sucesso"
echo "################################################################"
echo "Instalando o PHP"
apt-get -y install php php-fpm php-pdo php-gd php-mysqlnd php-mbstring php-common php-gettext php-curl php-cli;
echo "PHP realizado com sucesso"
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
atualizar
novalista
padroes
interativos

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
echo -e "Pressione <Enter> para concluir o processo."
# opção do comando date: + (format), %d (day), %m (month), %Y (year 1970), %H (hour 24), %M (minute 60)
echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n"
exit 0