sudo apt-get update

# essential tools for work
sudo apt-get install openssh-client openssh-server cpanminus ctags git postgresql-9.5 vim byobu sox libpq-dev

# essential tools - personal
sudo apt-get install namp wine tcl build-essential xclip ack-grep

# For kde connect and indicator
sudo add-apt-repository ppa:vikoadi/ppa

# For cinnamon desktop
sudo add-apt-repository ppa:embrosyn/cinnamon
sudo apt-get update

# To install extra apps, cinnamon, themes, etc..
sudo apt-get install indicator-kdeconnect kdeconnect perlbrew cinnamon blueberry numix-gtk-theme disper

# clean up
sudo apt-get autoremove

sudo cpanm Data::Dumper Term::Size::Any Catalyst::Plugin::Cache Catalyst::Authentication::Store::DBIx::Class Log::Log4perl JSON::WebToken Config::JSON Sysadm::Install File::Type DBD::Pg 

sudo cpanm <doc/modlist 
