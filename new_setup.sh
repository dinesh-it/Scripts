sudo apt-get update

# essential tools for work
sudo apt-get install openssh-client openssh-server cpanminus ctags git vim byobu sox libpq-dev openjdk-9-jre python-setuptools python-dev nmap tcl build-essential xclip ack apache2 apache2-utils python-setuptools python-dev build-essential redis-server nodejs perl-doc autorun autoconf libtool resolvconf openresolv network-manager-openvpn network-manager-openvpn-gnome pavucontrol npm

# Install Postgress
sudo apt install postgresql-9.6

# For kde connect and indicator
# XXX: Not available from 17.10
# sudo add-apt-repository ppa:vikoadi/ppa
# sudo apt-get update

# To install extra apps etc..
sudo apt-get install kdeconnect perlbrew disper

sudo cpanm Data::Dumper Term::Size::Any Catalyst::Plugin::Cache Catalyst::Authentication::Store::DBIx::Class Log::Log4perl JSON::WebToken Config::JSON Sysadm::Install File::Type DBD::Pg Perl::Tidy Data::UUID::MT DBIx::Class::Schema::Loader Module::Build

if [ $1 ]
do
sudo cpanm <$1 
done

echo "Install sox, dropbox, skype, slack, telegram by direct download deb's"
