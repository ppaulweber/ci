#!/bin/bash
#
#   Copyright (C) 2016-2018 Philipp Paulweber
#   All rights reserved.
#
#   Developed by: Philipp Paulweber
#                 <https://github.com/ppaulweber/ci>
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
    message "usage: $app <install|remove>"
    message "       $app <server> [config]"
    message "       $app <worker|retire> [config]"
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

cfg_default=etc/ci.conf
cfg_example=etc/example.conf

url=https://github.com/concourse/concourse/releases
bin_path=bin
bin_name=concourse
bin_ext=''
arch="amd64"
plat=""
if [ "$OSTYPE" == "linux-gnu" ]; then
    plat="linux"
elif [ "$OSTYPE" == "darwin*" ]; then
    plat="darwin"
elif [ "$OSTYPE" == "cygwin" ]; then
    plat="windows"
    bin_ext=".exe"
else
    error "unsupported system '$OSTYPE'"
fi

file=concourse_${plat}_${arch}${bin_ext}
bin=${bin_path}/${bin_name}${bin_ext}
app=`basename $0`
cwd=`pwd -P`
dir=`dirname $(realpath $0)`

function main
{
    if [ "$dir" != "$cwd" ]; then
	error "$app has to be executed inside its root directory!"
    fi

    if [ ! -f $bin ]; then
	warning "'$bin' not found, trying to fetch latest version"
	update
    fi

    local cmd=$1
    if [ -z "$cmd" ]; then
	error "no 'command' argument provided"
    fi

    local cfg=$2
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


    if [ "$cmd" = "remove" ]; then
	$cmd
    elif [ "$cmd" = "update" ]; then
	$cmd
    elif [ "$cmd" = "server" ]; then
	$cmd
    elif [ "$cmd" = "worker" ]; then
	$cmd
    elif [ "$cmd" = "retire" ]; then
	$cmd
    else
	error "invalid command '$cmd' provided"
    fi

}

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
    mkdir -p $bin_path

    local tag=`curl -s -# ${url}/latest | egrep -o 'tag/(.*)\">' | sed 's/tag\///' | sed 's/\">//'`
    local bin_tag=${bin_path}/`echo ${tag} | sed "s/v//g"`

    if [ -e ${bin_tag} ]; then
	info "latest version ${tag} already installed"
	return
    fi


    wget -q --show-progress ${url}/download/${tag}/${file}

    chmod 755 $file
    local version=`./$file -v`
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
    else
	message "concourse version ${tag}"
    fi
}


function server
{
    check_if_bin_exists_else_fetch_it

    message "starting concourse server"

    $bin web \
         --github-auth-client-id=$github_auth_client_id \
         --github-auth-client-secret=$github_auth_client_secret \
         --github-auth-user=$github_auth_users \
         --session-signing-key $server_key_signing_private \
         --tsa-host-key $server_key_private \
         --tsa-authorized-keys $server_key_authorized_workers \
         --postgres-data-source $database_addr \
         --external-url $server_url
}


function worker
{
    check_if_bin_exists_else_fetch_it

    mkdir -p $worker_dir

    message "starting concourse worker"

    $bin worker \
         --work-dir               $worker_dir \
         --tsa-host               $server_addr:$server_port \
         --tsa-public-key         $server_key_public \
         --tsa-worker-private-key $worker_key_private
}


function retire
{
    check_if_bin_exists_else_fetch_it

    source $cfg

    message "retire concourse worker"

    $bin retire-worker \
         --tsa-host               $server_addr:$server_port \
         --tsa-public-key         $server_key_public \
         --tsa-worker-private-key $worker_key_private
}

main $*


# cd jq
# autoreconf -i
# ./configure --disable-maintainer-mode
# make
