## Installation

1. Add my Debian repository to your list of sources, either by adding the following line to `/etc/apt/sources.list`
   
    ```
    deb https://repo.uwe-gehring.de/apt/debian ./  # Uwe Gehring's repo
    ```
   
   or better create a new file `/etc/apt/sources.list.d/uwe-gehring.list` with:
   
    ```sh
    $ sudo echo "deb https://repo.uwe-gehring.de/apt/debian ./" > /etc/apt/sources.list.d/uwe-gehring.list
    ```

2. Import verification key with:
   
    ```sh
    $ wget -qO - https://repo.uwe-gehring.de/apt.key | sudo apt-key add -
    ```

3. Refresh apt database:
   
    ```sh
    $ sudo apt-get update
    ```

4. Install the package with
   
    ```sh
    $ sudo apt-get install vhostmanager
    ```

Alternatively you can download the binary package from [here](https://repo.uwe-gehring.de/apt/debian/binary) and install it with:

```sh
$ sudo dpkg -i package
```

However, this would not resolve any dependencies.
