#!/bin/bash
#   
#   Copyright (c) 2016 Philipp Paulweber
#   All rights reserved.
#   
#   Developed by: Philipp Paulweber
#                 https://github.com/ppaulweber/ci
#   
#   This file is part of ci.
#   
#   ci is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#   
#   ci is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with ci. If not, see <http://www.gnu.org/licenses/>.
#   

app=`basename $0`
cwd=`pwd -P`
dir=`dirname $(realpath $0)`

cfg_default=etc/ci.conf
cfg_example=etc/ci.example.conf

u=`tput smul`
u_=`tput rmul`
b=`tput bold`
c=`tput sgr0`

function message
{
    if [ -z "$1" ]; then
        echo "internal error: no message provided"
        exit -1
    fi
    echo "${b}$app: $1 ${c}"
}

function usage
{
    message "usage: $app <worker|server|update|remove> [config]"
}

function info
{
    message "info: $1"
}

function warning
{
    message "warning: $1"
}

function error
{
    message "error: $1"
    usage
    exit -1
}


if [ "$dir" != "$cwd" ]; then
    error "$app has to be executed inside its root directory!"
fi

if [ ! -f $bin ]; then
    warning "'$bin' not found, trying to fetch latest version"
    update
fi



cmd=$1
if [ -z "$cmd" ]; then
    error "no 'command' argument provided"
fi

cfg=$2
if [ -z "$cfg" ]; then
    cfg=$cfg_default
    info "no 'config' argument provided, using default config '$cfg'"

    if [ ! -f $cfg ]; then
        info "no default config found, creating a skeleton"
        cp $cfg_example $cfg_default
    fi
fi

if [ ! -f $cfg ]; then
    error "unable to load config file '$cfg'"
fi

source $cfg

## TODO: FIXME: @ppaulweber: add config file checks here!!!



bin=$bin_path/$bin_name

function remove
{
    if [ -d $bin_path ]; then
        rm -f $bin_path/*
        rmdir $bin_path
        message "removed all concourse binaries from path '$bin_path'"
    fi
}

function update
{
    ## TODO: FIXME: @ppaulweber: fetching (aka. updating) works only for linux at the moment
    # concourse_darwin_amd64
    # concourse_linux_amd64
    # concourse_windows_amd64.exe 
    
    file=concourse_${plat}_${arch}
    
    mkdir -p $bin_path
    
    tag=`curl https://github.com/concourse/concourse/releases/latest | egrep -o 'tag/(.*)\">' | sed 's/tag\///' | sed 's/\">//'`
    wget https://github.com/concourse/concourse/releases/download/$tag/$file
    
    chmod 755 $file
    version=`./$file -v`
    mv $file $version
    
    rm -f $bin
    ln -s $version $bin_name
    mv $version  $bin_path
    mv $bin_name $bin_path
    
    if [ ! -f $bin ]; then
        error "'$bin' could not be installed"
    fi
    
    message "updated to concourse version '$version' for '$plat' and '$arch'"
}

function check_if_bin_exists_else_fetch_it
{
    if [ ! -f $bin ]; then
        warning "'$bin' not found, trying to fetch latest version"
        update
    fi
}

function worker
{
    check_if_bin_exists_else_fetch_it
    
    mkdir -p $worker_dir
    
    
    message "starting concourse worker"
    
    $bin worker \
         --work-dir               $worker_dir \
         --tsa-host               $server_addr \
         --tsa-public-key         $server_key_public \
         --tsa-worker-private-key $worker_key_private
}


function server
{
    check_if_bin_exists_else_fetch_it

    message "starting concourse server"
    
    # $bin web
    ## TODO: FIXME: @ppaulweber: continue wrapper call of concourse for server application
    error "unimplemented"
}





case "$cmd" in
    worker);&
    server);&
    update);&
    remove)
        $cmd
        ;;
    *)
        error "invalid command '$cmd' provided"
        ;;
esac
