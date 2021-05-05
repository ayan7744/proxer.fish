# proxer - automatic proxy script
Minimal proxy connection script
## Installation and Usage
Add the following line to your `.bashrc` or `.zshrc`: 
```bash
source /path/to/proxer.bash
```
or alternatively, run the following commands
```bash
curl "https://raw.githubusercontent.com/ayan7744/proxer/master/proxer.bash" > ~/.local/bin/proxer.bash
[ -f ~/.bashrc ] && echo "source ~/.local/bin/proxer.bash" >> ~/.bashrc
[ -f ~/.zshrc ] && echo "source ~/.local/bin/proxer.bash" >> ~/.zshrc
``

## Configuration
Read `~/.config/proxer/proxer.rc` or `$XDG_CONFIG_HOME/proxer/proxer.rc` for information.
