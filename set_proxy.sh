#!/bin/sh
# Script to set system-wide proxy in Arch

# if IS_PROXY_SET env var doesn't exist, then export it.
[ -z "$IS_PROXY_SET" ] && export IS_PROXY_SET=0

if [ -z "$XDG_CONFIG_HOME" ]; then
    configFile="$HOME/.config/proxer/proxy"
else 
    configFile="$XDG_CONFIG_HOME/proxer/proxy"
fi

configFileHead="$(/bin/cat $configFile | head -1)"
connectedWifi="$(nmcli -t -f NAME connection show --active)"
ssid="$(echo "$configFileHead" | cut -d' ' -f1)"
proxyHost="$(echo "$configFileHead" | cut -d' ' -f2)"
proxyPort="$(echo "$configFileHead" | cut -d' ' -f3)"
proxyUser="$(echo "$configFileHead" | cut -d' ' -f4)"
proxyPass="$(echo "$configFileHead" | cut -d' ' -f5)"

if [ -z "$proxyUser" ]; then 
    proxyServer="http://$proxyHost:$proxyPort/"
elif [ -z "$proxyPass" ]; then 
    proxyServer="http://$proxyUser@$proxyHost:$proxyPort/"
else 
    proxyServer="http://$proxyUser:$proxyPass@$proxyHost:$proxyPort/"
fi

check_su() {
    if [ `id -u` -ne 0 ]; then 
        echo "Must be run with root privileges. Exiting..."
        exit 1
    fi
}

_exit() {
    echo "proxer: invalid option"
    echo "Usage: proxer -h [PROXY HOST] -p [PROXY PORT]"
    echo "Try 'proxer --help' for more information."
    # Help to be added later when script functions increases
    exit 1
}

# setting system wide proxy
gsettings_proxy () {
    if [ "$1" = "--set" ]; then 
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.http host "$2"
        gsettings set org.gnome.system.proxy.http port "$3"
        gsettings set org.gnome.system.proxy.https host "$2"
        gsettings set org.gnome.system.proxy.https port "$3"
        gsettings set org.gnome.system.proxy.ftp host "$2"
        gsettings set org.gnome.system.proxy.ftp port "$3"
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1', 'localaddress','.localdomain.com', '::1', '10.*.*.*']"
    elif [ "$1" = "--unset" ]; then
        gsettings set org.gnome.system.proxy mode none
    else 
        exit 1
    fi 
}

# setting APT-conf proxy

## in /etc/apt/apt.conf.d/70debconf
apt_proxy () {
}

# setting environment variables
env_proxy () { 
    if [ "$1" = "--set" ]; then 
        export http_proxy="$2"
        export HTTP_PROXY="$http_proxy"
        export https_proxy="$http_proxy"
        export HTTPS_PROXY="$http_proxy"
        export ftp_proxy="$http_proxy"
        export FTP_PROXY="$http_proxy"
        export rsync_proxy="$http_proxy"
        export RSYNC_PROXY="$http_proxy"
        export all_proxy="$http_proxy"
        export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
    elif [ "$1" = "--unset" ]; then
        unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY rsync_proxy RSYNC_PROXY all_proxy no_proxy
    else 
        exit 1
    fi 
}

# manage git proxy
git_proxy () {
    if [ "$1" = "--set" ]; then 
        if hash git 2>/dev/null; then
          git config --global http.proxy "$2"
          git config --global https.proxy "$2"
        fi
    elif [ "$1" = "--unset" ]; then
        if hash git 2>/dev/null; then
          git config --global --unset http.proxy
          git config --global --unset https.proxy
        fi
    else 
        exit 1
    fi 
}

set_all_proxy() {
    [ "$IS_PROXY_SET" = "1" ] && return 0   
    gsettings_proxy --set "$proxyHost" "$proxyPort"
    git_proxy --set "$proxyServer"
    env_proxy --set "$proxyServer"
    export IS_PROXY_SET=1
}

unset_all_proxy() {
    [ "$IS_PROXY_SET" = "0" ] && return 0   
    gsettings_proxy --unset
    git_proxy --unset
    env_proxy --unset
    export IS_PROXY_SET=0
}

auto_proxy() {
    if [ "$connectedWifi" = "$ssid" ]
        set_proxy "$proxyServer"
    else
        unset_proxy
    fi
}

reset_proxy() {
    unset_all_proxy
    sed -i.bak "/Acquire::/d" /etc/apt/apt.conf
    sed -i.bak "/Acquire::/,+10d" /etc/apt/apt.conf.d/70debconf
}

if [ "$#" -eq 1 ]; then
  case $1 in    
    -u| --unset)    
      reset_proxy
      exit 0
      ;;
    *)          
      exit_with_usage 
      ;;
  esac
fi

if [ "$#" -eq 4 ]; then
  while [ "$1" != "" ]; do
    case $1 in
      -h| --host)
        shift
        PROXY_HOST=$1
        echo $PROXY_HOST
        shift
        case $1 in
          -p| --port)
            shift
            PROXY_PORT=$1
            echo $PROXY_PORT
            shift
            ;;
          *) 
            exit_with_usage 
            ;;
        esac
        ;;
      *) 
        exit_with_usage 
        ;;
    esac
  done
  else
    exit_with_usage
fi
