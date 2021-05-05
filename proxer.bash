#!/bin/bash

# MIT License
# Copyright (c) 2021 Ayan Nath

# proxer - script to set proxy settings on arch or arch based distributions.
# https://github.com/ayan7744/proxer

# USAGE: _urlencode_ STRING
_urlencode_() {
    # https://gist.github.com/cdown/1163649
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

# USAGE: _gsettings_proxy_ [ --set | --unset ] PROXY_HOST PROXY_PORT USERNAME PASSWORD
_gsettings_proxy_() {
    if [ "$1" = "--set" ]; then 
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.http enabled true
        gsettings set org.gnome.system.proxy.http host "$2"
        gsettings set org.gnome.system.proxy.http port "$3"
        gsettings set org.gnome.system.proxy use-same-proxy true
        [ -z "$4" ] || gsettings set org.gnome.system.proxy.http authentication-user "$4"
        [ -z "$5" ] || gsettings set org.gnome.system.proxy.http authentication-password "$5"
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1', 'localaddress','.localdomain.com', '::1', '10.*.*.*']"
    elif [ "$1" = "--unset" ]; then
        gsettings set org.gnome.system.proxy mode none
    else 
        exit 1
    fi 
}

# USAGE: _apt_proxy_ [ --set | --unset ] PROXY_HOST PROXY_PORT USERNAME PASSWORD
# _apt_proxy_ () {
#   write to /etc/apt/apt.conf.d/proxyconf
# }

# USAGE: _env_proxy_ [ --set | --unset ] PROXY_SERVER
_env_proxy_() { 
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
        export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com,::1,10.*.*.*"
    elif [ "$1" = "--unset" ]; then
        unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY rsync_proxy RSYNC_PROXY all_proxy no_proxy
    else 
        exit 1
    fi 
}

# USAGE: _git_proxy_ [ --set | --unset ] PROXY_SERVER
_git_proxy_() {
    which git &>/dev/null || return 0 
    if [ "$1" = "--set" ]; then 
        git config --global http.proxy "$2"
        git config --global https.proxy "$2"
    elif [ "$1" = "--unset" ]; then
        git config --global --unset http.proxy
        git config --global --unset https.proxy
    else 
        exit 1
    fi 
}

# USAGE: set_all_proxy PROXY_HOST PROXY_PORT USERNAME PASSWORD
_set_all_proxy_() {
    # define proxyServer properly
    if [ -z "$3" ]; then 
        proxyServer="http://$1:$2/"
    elif [ -z "$4" ]; then 
        proxyServer="http://$3@$1:$2/"
    else 
        proxyServer="http://$3:$4@$1:$2/"
    fi
    
    # check if the same proxy is already set
    if [ "$IS_PROXY_SET" = true ] && [ "$http_proxy" = "$proxyServer" ]; then
        return 0   
    fi

    _gsettings_proxy_ --set "$1" "$2" "$3" "$4"
    _git_proxy_ --set "$proxyServer"
    _env_proxy_ --set "$proxyServer"
    export IS_PROXY_SET=true
}

# USAGE: _unset_all_proxy
_unset_all_proxy_() {
    [ "$IS_PROXY_SET" = false ] && return 0   
    _gsettings_proxy_ --unset
    _git_proxy_ --unset
    _env_proxy_ --unset
    export IS_PROXY_SET=false
}

# USAGE: _auto_proxy_
_auto_proxy_() {
    conSsid="$(nmcli -t -f NAME connection show --active)"
    local matchFound=false 
    if [ "$check_bssid" = true ]; then 
        conBssid="$(nmcli -f IN-USE,BSSID device wifi | awk '/^\*/{if (NR!=1) {print $2}}')"
        for ((i=0 ; ; i++)); do
            [ -z "${con[${i},Host]}" ] && break 
            if [[ -n "${con[${i},SSID]}" && "${con[${i},SSID]}" == "$conSsid" ]] || [[ -n "${con[${i},BSSID]}" && "${con[${i},BSSID]}" == "$conBssid" ]]; then
                local username
                local password
                username="$(_urlencode_ "${con[${i},Username]}")"
                password="$(_urlencode_ "${con[${i},Password]}")"
                _set_all_proxy_ "${con[${i},Host]}" "${con[${i},Port]}" "$username" "$password"
                matchFound=true
                break
            fi
        done
    else
        for ((i=0 ; ; i++)); do
            [ -z "${con[${i},Host]}" ] && break 
            if [[ -n "${con[${i},SSID]}" && "${con[${i},SSID]}" == "$conSsid" ]]; then
                local username
                local password
                username="$(_urlencode_ "${con[${i},Username]}")"
                password="$(_urlencode_ "${con[${i},Password]}")"
                _set_all_proxy_ "${con[${i},Host]}" "${con[${i},Port]}" "$username" "$password"
                matchFound=true
                break
            fi
        done
    fi
    [ "$matchFound" = false ] && _unset_all_proxy_
}

# USAGE: log "DEBUG_INFO"
# log() {
#     LOGGING=true
#    logfile="/tmp/proxer.log"
#    [ $LOGGING = true ] && echo "[$(date)] $*" >> $logfile
# }

# USAGE: _main_
_main_() {
    # if IS_PROXY_SET isn't set then export it.
    [ -z "$IS_PROXY_SET" ] && export IS_PROXY_SET=false

    # set configuration directory
    if [ -z "$XDG_CONFIG_HOME" ]; then
        confDir="$HOME/.config/proxer"
    else 
        confDir="$XDG_CONFIG_HOME/proxer"
    fi

    # make configuration directory if it doesn't exist and create an example file
    [ -d "$confDir" ] || mkdir -p "$confDir"

    # make ${confDir}/proxer.rc if $confDir if it doesn't exist
    [ -f "${confDir}/proxer.rc" ] || tee -a "$confDir"/proxer.rc &>/dev/null <<EOF
# MIT License
# Copyright (c) 2021 Ayan Nath

# https://github.com/ayan7744/proxer

# proxer - configuration file
# This file is sourced everytime. 
# All lines beginning with '#' are treated as comments.

### Connections ###
# SSID is the name of the wifi connection.
# BSSID of an wifi connection can be found using "nmcli device wifi list".
# Host is the address of the proxy server (for example, 192.168.3.10).
# Port is the port number of the proxy server (for example, 3128).
# If a field is not applicable leave it blank.
# List out all the connections as shown below and don't forget to uncomment the lines.

# con[0,SSID]="wifi name"; con[0,Host]="192.168.3.10"; con[0,Port]="3128"; con[0,Username]="myuser"; con[0,Password]="";

# con[1,SSID]="wifi name 2"; con[1,BSSID]="E4:6F:13:4D:64:20"; con[1,Host]="192.168.4.11"; con[1,Port]="8080"; con[1,Username]="foo"; con[1,Password]="bar";

### Options ###
# Change to true to check for BSSIDs if provided.
check_bssid=false
EOF
    # declare associative array con
    declare -A con
    # source configuration scripts
    # shellcheck disable=SC1091
    source "${confDir}/proxer.rc"
    _auto_proxy_
}

# execute master function
_main_

# unset all functions
unset -f _main_ _auto_proxy_ _unset_all_proxy_ _set_all_proxy_ _git_proxy_ _env_proxy_ _gsettings_proxy_ _check_su_ _urlencode_
