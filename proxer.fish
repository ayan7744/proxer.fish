#!/bin/fish

# MIT License
# Copyright (c) 2021 Ayan Nath

# proxer - script to set system-wide proxy on arch or arch based distributions
# https://github.com/ayan7744/proxer

# USAGE: _gsettings_proxy_ [ --set | --unset ] PROXY_HOST PROXY_PORT USERNAME PASSWORD

function _gsettings_proxy_
    if test "$argv[1]" = "--set" 
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.http enabled true
        gsettings set org.gnome.system.proxy.http host "$argv[2]"
        gsettings set org.gnome.system.proxy.http port "$argv[3]"
        gsettings set org.gnome.system.proxy.https host "$argv[2]"
        gsettings set org.gnome.system.proxy.https port "$argv[3]"
        gsettings set org.gnome.system.proxy.ftp host "$argv[2]"
        gsettings set org.gnome.system.proxy.ftp port "$argv[3]"
        gsettings set org.gnome.system.proxy.http authentication-user "$argv[4]"
        gsettings set org.gnome.system.proxy.http authentication-password "$argv[5]"
        gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1', 'localaddress','.localdomain.com', '::1', '10.*.*.*']"
    else if test "$argv[1]" = "--unset" 
        gsettings set org.gnome.system.proxy mode none
    else 
        return 1
    end 
end

# USAGE: _env_proxy_ [ --set | --unset ] PROXY_ADDRESS
function _env_proxy_
    if test "$argv[1]" = "--set" 
        set -Ux http_proxy "$argv[2]"
        set -Ux HTTP_PROXY "$http_proxy"
        set -Ux https_proxy "$http_proxy"
        set -Ux HTTPS_PROXY "$http_proxy"
        set -Ux ftp_proxy "$http_proxy"
        set -Ux FTP_PROXY "$http_proxy"
        set -Ux rsync_proxy "$http_proxy"
        set -Ux RSYNC_PROXY "$http_proxy"
        set -Ux all_proxy "$http_proxy"
        set -Ux no_proxy "localhost,127.0.0.1,localaddress,.localdomain.com,::1,10.*.*.*"
    else if  test "$argv[1]" = "--unset"
        set -Ue http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY rsync_proxy RSYNC_PROXY all_proxy no_proxy
    else 
        return 1
    end 
end

# USAGE: _git_proxy_ [ --set | --unset ] PROXY_ADDRESS
function _git_proxy_
    if test "$argv[1]" = "--set"
        git config --global http.proxy "$argv[2]"
        git config --global https.proxy "$argv[2]"
    else if test "$argv[1]" = "--unset"
        git config --global --unset http.proxy
        git config --global --unset https.proxy
    else 
        return 1
    end
end

# USAGE: _set_all_proxy_ PROXY_HOST PROXY_PORT USERNAME PASSWORD PROXY_ADDRESS
function _set_all_proxy_
    _gsettings_proxy_ --set "$argv[1]" "$argv[2]" "$argv[3]" "$argv[4]"
    _git_proxy_ --set "$argv[5]"
    _env_proxy_ --set "$argv[5]"
end

# USAGE: _unset_all_proxy
function _unset_all_proxy_
    _gsettings_proxy_ --unset
    _git_proxy_ --unset
    _env_proxy_ --unset
end

# USAGE: _auto_proxy_ PROXY_HOST PROXY_PORT USERNAME PASSWORD PROXY_ADDRESS WIFI_SSID
function _auto_proxy_
    set conSSID (nmcli -t -f NAME connection show --active)
    if test "$IS_PROXY_SET" = true
        if test "$conSSID" != "$argv[6]"
            _unset_all_proxy_
            set -e IS_PROXY_SET &> /dev/null
            set -Ux IS_PROXY_SET false
        end
    else if test "$IS_PROXY_SET" = false
        if test "$conSSID" = "$argv[6]"
            _set_all_proxy_ "$argv[1]" "$argv[2]" "$argv[3]" "$argv[4]" "$argv[5]"
            set -e IS_PROXY_SET &> /dev/null
            set -Ux IS_PROXY_SET true
        end
    end
end

# USAGE: log "MSG"
# function log
#   set -l LOGGING true
#   set -l logfile "/tmp/proxer.log"
#   set dt (date)
#    if test $LOGGING = true
#       echo "[$dt] $argv" >> $logfile
#  end
# end

# USAGE: _main_
function _main_
    # if IS_PROXY_SET variable isn't set then export it.
    if test -z "$IS_PROXY_SET"
        set -Ux IS_PROXY_SET false
    end

    # set configuration directory
    set confDir "$XDG_CONFIG_HOME/proxer"
    set confFile "$confDir/proxer.rc.fish"

    # source configuration scripts
    source "$confFile"
    _auto_proxy_ "$proxy_host" "$proxy_port" "$username" "$password" "$proxy_address" "$wifi_SSID"
end

# execute master function
_main_

# erase all functions and variables
functions -e _main_ _auto_proxy_ _unset_all_proxy_ _set_all_proxy_ _git_proxy_ _env_proxy_ _gsettings_proxy_
