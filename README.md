
<!-- ABOUT VHOSTMANAGER -->
## vhostmanager
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/Adspectus/vhostmanager?style=flat-square&label=Version)](https://github.com/Adspectus/vhostmanager/releases)
[![GitHub issues](https://img.shields.io/github/issues/Adspectus/vhostmanager?style=flat-square)](https://github.com/Adspectus/vhostmanager/issues)
[![GitHub license](https://img.shields.io/github/license/Adspectus/vhostmanager?style=flat-square)](https://github.com/Adspectus/vhostmanager/blob/master/LICENSE)

The __vhostmanager__ package is a collection of configuration files and scripts to enable a user specific Apache2 configuration. It provides the optional inclusion of configurations and virtual host definitions from directories in `$HOME/apache2`. Furthermore it provides scripts to manage these configuration files in a similar way like the standard tools provided by the apache2 package.

<!-- TABLE OF CONTENTS -->
## Contents

* [Getting Started](#getting-started)
* [Usage](#usage)
* [License](#license)
* [Acknowledgements](#acknowledgements)



<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* Debian based OS
* Apache2 Webserver > 2.4
* _Perl 5_

### Installation

See the installation instructions in [INSTALL.md](./INSTALL.md).

After installation of the package, create the directories for your personal configuration files with:

```sh
$ mkdir -p $HOME/apache2/{conf,sites}-{available,enabled}
```


<!-- USAGE EXAMPLES -->
## Usage

After installation and creating the directories you should have the following directory structure in your home directory:

```
$HOME/apache2/
├── conf-available/
├── conf-enabled/
├── sites-available/
└── sites-enabled/
```

Apache2 will include all configurations files (ending in `.conf`) from the `$HOME/apache2/conf-enabled` and the `$HOME/apache2/sites-enabled` directory of all users, if there are any. Note, that the users home directories are expected to be in `/home/`!

Like within the main Apache2 directory, the real files should be placed into the `$HOME/apache2/conf-available` and the `$HOME/apache2/sites-available` directory resp. and only symlinked to the `*-enabled` directories if they should be active.

The activation and deactivation of configurations and virtual hosts can be done by the provided commands `vhostenconf`, `vhostdisconf`, `vhostensite`, and `vhostdissite` just like their counterparts `a2enconf`, `a2disconf`, `a2ensite`, and `a2dissite` from the apache2 package, which are limited to the main Apache2 directory though.

Like their counterparts, the `vhost*`commands work with tab-completion and for your convenience you can list i.e. all enabled sites with the command `vhostquery -s` (like `a2query -s` for the main Apache2 sites).

## User specific virtual hosts directory

Of course, after installation of this package it might also makes sense to place the root of user specific virtual hosts into a user defined directory as well.

This decision is left to the user, however `$HOME/public_html` would not be a good choice since it is already reserved for the per-user web-directory in Apache2 (if enabled). Instead, `$HOME/vhosts` might be a reasonable option.

Whatever you choose, it might be necessary to open permissions for the user specific virtual host root folder, because under the default security model of the Apache2 server it is not allowed to access the root filesystem outside of `/usr/share` and `/var/www` resp. Hence, you will likely create a configuration file in your `conf-available` directory with at least the following lines, assuming the virtual host root folder is `$HOME/vhosts` (replace `<HOMEDIR>` with the real path of your home directory):

    <Directory <HOMEDIR>/vhosts>
      Options Indexes FollowSymLinks
      AllowOverride None
      Require all granted
    </Directory>

The `/usr/share/doc/vhostmanager/examples` directory contains an example configuration in the file `vhostmanager.conf` with this and some more example configuration directives which might further simplify your life.

_For more help, please refer to the man page of each command._


<!-- LICENSE -->
## License

[Apache License 2.0](LICENSE)


<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* a2enmod by Stefan Fritsch
* a2query by Arno Töll


