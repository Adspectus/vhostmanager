[![GitHub issues](https://img.shields.io/github/issues/Adspectus/vhostmanager?style=flat-square)](https://github.com/Adspectus/vhostmanager/issues)
[![GitHub license](https://img.shields.io/github/license/Adspectus/vhostmanager?style=flat-square)](https://github.com/Adspectus/vhostmanager/blob/master/LICENSE)


<!-- TABLE OF CONTENTS -->
## Table of Contents

* [About vhostmanager](#about)
* [Getting Started](#getting-started)
* [Usage](#usage)
* [License](#license)
* [Acknowledgements](#acknowledgements)


<!-- ABOUT VHOSTMANAGER -->
## About

The __vhostmanager__ package is a collection of configuration files and scripts to enable a user specific Apache2 configuration. It provides the optional inclusion of configurations and virtual host definitions from directories in `$HOME/apache2`. Furthermore it provides scripts to manage these configuration files in a similar way like the standard tools provided by the apache2 package.

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* Debian based OS
* Apache2 Webserver > 2.4
* _Perl 5_

### Installation

1. Add my Debian repository to your list of sources, either by adding the following line to `/etc/apt/sources.list`
   
    ```sh
    deb https://repo.uwe-gehring.de/apt/debian ./  # Uwe Gehring's repo
    ```
   
   or better create a new file `/etc/apt/sources.list.d/uwe-gehring.list` with:
   
    ```sh
    sudo echo "deb https://repo.uwe-gehring.de/apt/debian ./" > /etc/apt/sources.list.d/uwe-gehring.list
    ```

2. Import verification key with:
   
    ```sh
    wget -qO - https://repo.uwe-gehring.de/apt.key | sudo apt-key add -
    ```

3. Refresh apt database:
   
    ```sh
    sudo apt-get update
    ```

4. Install the package with
   
    ```sh
    sudo apt-get install vhostmanager
    ```

5. Create directories for your personal configuration files with
   
    ```sh
    mkdir -p $HOME/apache2/{conf,sites}-{available,enabled}
    ```


<!-- USAGE EXAMPLES -->
## Usage

This package installs 2 files, one in our `/etc/apache2/conf-enabled` and one in your `/etc/apache2/sites-enabled` directory. Each file is named `vhostmanager.conf` and contains the following line:

```
IncludeOptional /home/*/apache2/conf-enabled/*.conf
```

and

```
IncludeOptional /home/*/apache2/sites-enabled/*.conf
```

resp., which means Apache2 will include all `.conf` files in the given directories for each user. Thus, it is easy to include user specific configurations files and user specific virtual host configuration files.

Following the Debian flavour of an Apache2 installation, these configuration files should be placed in a `conf-available` and `sites-available` subdirectory in a users `apache2` directory and only those configurations and virtual hosts which should be active, should be symlinked to the `conf-enabled` and `sites-enabled` subdirectory resp.

The activation and deactivation of configurations and virtual hosts can be done by the provided commands `vhostenconf`, `vhostdisconf`, `vhostensite`, and `vhostdissite` just like their counterparts `a2enconf`, `a2disconf`, `a2ensite`, and `a2dissite` from the apache2 package, which are limited to the main Apache2 directory though.

Like their counterparts, the `vhost*`commands work with tab-completion and for your convenience you can list i.e. all enabled sites with the command `vhostquery -s` (like `a2query -s` for the main Apache2 sites).

Of course it might makes sense to place the root of user specific virtual hosts into a user defined directory as well. The decision is left to the user but `$HOME/public_html` is not a good choice since this is already reserved for the per-user web-directory in Apache2 (if enabled). `$HOME/vhosts` might be a reasonable option.

Whatever you choose, it might be necessary to open permissions for the user specific virtual host root folder, because under the default security model of the Apache2 server it is not allowed to access the root filesystem outside of `/usr/share` and `/var/www` resp. Hence, you will likely create a configuration file in your `conf-available` directory with at least the following lines, assuming the virtual host root folder is `$HOME/apache2` (replace `<HOMEDIR>` with the real path of your home directory):

    <Directory <HOMEDIR>/vhosts>
      Options Indexes FollowSymLinks
      AllowOverride None
      Require all granted
    </Directory>

The `/usr/share/doc/vhostmanager/examples` directory contains an example configuration file with this and some more example configuration directives which might further simplify your life.

_For more help, please refer to the man page of each command._


<!-- LICENSE -->
## License

[Apache License 2.0](LICENSE)


<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* a2enmod by Stefan Fritsch
* a2query by Arno Töll


