#!/bin/sh
# Script to set system-wide proxy in Arch

check_su() {
    if [ `id -u` -ne 0 ]; then 
        echo "Must be run with root privileges. Exiting..."
        exit 1
    fi
}

_exit() {
    echo "proxer: invalid option"
    echo "Usage: ./set_proxy.sh -h [PROXY HOST] -p [PROXY PORT]"
    echo "Try './set_proxy.sh --help' for more information."
    # Help to be added later when script functions increases
    exit 1
}

reset_proxy () {
    gsettings set org.gnome.system.proxy mode none
    truncate -s 0 /etc/profile.d/proxy.sh
    sed -i.bak "/Acquire::/d" /etc/apt/apt.conf
    sed -i.bak "/Acquire::/,+10d" /etc/apt/apt.conf.d/70debconf
    sed -i "/proxy/d" /etc/environment
    sed -i "/PROXY/d" /etc/environment
    if hash git 2>/dev/null; then
      git config --global --unset http.proxy
      git config --global --unset https.proxy
    fi
    if [ -a /etc/systemd/system/docker.service.d/proxy.conf ]; then
      sudo rm -rf /etc/systemd/system/docker.service.d/proxy.conf
    fi
    sudo systemctl daemon-reload
    sudo systemctl restart docker.service
}

# setting system wide proxy
gsettings_proxy () {
    if [ "$1" = "--set" ]; then 
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.http host "$PROXY_HOST"
        gsettings set org.gnome.system.proxy.http port "$PROXY_PORT"
        gsettings set org.gnome.system.proxy.https host "$PROXY_HOST"
        gsettings set org.gnome.system.proxy.https port "$PROXY_PORT"
        gsettings set org.gnome.system.proxy.ftp host "$PROXY_HOST"
        gsettings set org.gnome.system.proxy.ftp port "$PROXY_PORT"
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1', 'localaddress','.localdomain.com', '::1', '10.*.*.*']"
    elif [ "$1" = "--unset" ]; then
        [ "$IS_PROXY_SET" = "0" ] && return 0
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
        [ "$IS_PROXY_SET" = "1" ] && return 0   
        export http_proxy=$argv[1]
        export HTTP_PROXY=$http_proxy
        export https_proxy=$http_proxy
        export HTTPS_PROXY=$http_proxy
        export ftp_proxy=$http_proxy
        export FTP_PROXY=$http_proxy
        export rsync_proxy=$http_proxy
        export RSYNC_PROXY=$http_proxy
        export all_proxy=$http_proxy
        export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
        export IS_PROXY_ON=1
    elif [ "$1" = "--unset" ]; then
        [ "$IS_PROXY_SET" = "0" ] && return 0
        
    else 
        exit 1
    fi 
}

# set git proxy
set_git_proxy () {
    if hash git 2>/dev/null; then
      git config --global http.proxy "http://${PROXY_HOST}:${PROXY_PORT}"
      git config --global https.proxy "http://${PROXY_HOST}:${PROXY_PORT}"
    fi
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
