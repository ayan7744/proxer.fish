# proxer - automatic proxy script
<!--- ![built-with-love](https://img.shields.io/static/v1?label=Built%20with&message=%E2%9D%A4&color=red&style=for-the-badge) &nbsp; -->
![written-in-fish](https://img.shields.io/static/v1?label=Written%20in&message=fish&color=orange&style=for-the-badge) &nbsp;
<!--- ![works-on-linux](https://img.shields.io/static/v1?label=Works%20on&message=Linux&color=green&style=for-the-badge) -->

Minimal proxy script for arch and arch based distributions for fish users. Sets or unsets a proxy depending on the connected WiFi.

## Installation and Usage
It is a good idea to export the variable `$XDG_CONFIG_HOME` even if you use the default `~/.config/` directory.  Add `set -gx XDG_CONFIG_HOME /path/to/config/dir/` to your `config.fish` if you haven't already. Then add the following line to your `config.fish`:
```bash
source /path/to/proxer.fish
```
Or alternatively, run the following commands.
```bash
curl "https://raw.githubusercontent.com/ayan7744/proxer.fish/master/proxer.fish" > ~/.local/bin/proxer.fish
echo "set -gx XDG_CONFIG_HOME ~/.config/" >> ~/.config/fish/config.fish
echo "source ~/.local/bin/proxer.fish" >> ~/.config/fish/config.fish
```
## Configuration
The script sources the file `$XDG_CONFIG_HOME/proxer.rc.fish` everytime. Create the file `$XDG_CONFIG_HOME/proxer.rc.fish` with the following contents
```bash
set wifi_SSID "Some wifi name"
set proxy_host "192.168.3.10"
set proxy_port "3128"
set username "myuser"
set password "mypassword"
set proxy_address "http://$username:$password@$proxy_host:$proxy_port/"
```
Don't forget to URL encode your username and password.
## Dependencies
* NetworkManager
