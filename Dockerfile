
FROM centos:7

ENV BUGZILLA_FTP_URL 'https://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla-5.0.tar.gz'
ENV ADMIN_EMAIL 'admin@bugzilla.bugs'
ENV ADMIN_LOGIN 'admin'
ENV ADMIN_OK 'Y'
ENV ADMIN_PASSWORD 'admin'
ENV ADMIN_REALNAME 'QA Admin'
ENV DB_HOST 'localhost'
ENV DB_NAME 'bugs'
ENV DB_USER 'bugs'
ENV DB_PASS 'bugs'
ENV DB_PORT 3306

# Change SELinux mode from enforcing to permissive.
# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/g' /etc/selinux/config

# Install services, packages and do cleanup
RUN yum install httpd httpd-devel mod_ssl mod_ssl mod_perl mod_perl-devel \
	mariadb-server mariadb-devel php-mysql gcc gcc-c++ graphviz graphviz-devel \
	patchutils gd gd-devel wget perl* -x perl-homedir -y \
	&& rm -rf /var/lib/apt/lists/*


# Installing Bugzilla
RUN cd && \
	wget $BUGZILLA_FTP_URL && \
	mkdir /var/www/html/bugzilla && \
	tar -xzvf $(basename $BUGZILLA_FTP_URL) -C /var/www/html/bugzilla --strip-components=1 && \
	cd /var/www/html/bugzilla && \
	/usr/bin/perl install-module.pl --all && \
	sed -i 's/^Options -Indexes$/#Options -Indexes/g' ./.htaccess

COPY conf/answers.txt /conf/answers.txt

RUN cd /var/www/html/bugzilla && ./checksetup.pl /conf/answers.txt

RUN cd /var/www/html/bugzilla && ./checksetup.pl

# Apache ENVs
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV APACHE_SERVER_NAME localhost

COPY conf/bugzilla.conf /etc/httpd/conf.d/bugzilla.conf

# Expose Apache
EXPOSE 80

# Launch Apache
CMD ["/sbin/apachectl", "-DFOREGROUND"]