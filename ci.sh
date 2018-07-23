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
    message "       $app <worker|retire|land> [config]"
}

function main
{
    if [ "$cmd" = "remove" ]; then
	$cmd
	return
    fi

    if [ ! -f $bin ]; then
	warning "'$bin' not found, trying to fetch latest version"
	update
    fi

    if [ "$cmd" = "update" ]; then
	$cmd
    elif [ "$cmd" = "server" ]; then
	$cmd
    elif [ "$cmd" = "worker" ]; then
	$cmd
    elif [ "$cmd" = "retire" ]; then
	$cmd
    elif [ "$cmd" = "land" ]; then
	retire land
    elif [ "$cmd" = "start" ]; then
	$cmd
    elif [ "$cmd" = "stop" ]; then
	$cmd
    else
	error "invalid command '$cmd' provided"
    fi
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
plat=''
if [ "$OSTYPE" == "linux-gnu" ]; then
    plat="linux"
elif [ "$OSTYPE" == "darwin*" ]; then
    plat="darwin"
elif [ "$OSTYPE" == "cygwin" ] || [ "$OSTYPE" == "msys" ]; then
    plat="windows"
    bin_ext=".exe"
else
    error "unsupported system '$OSTYPE'"
fi

# if [ "$plat" == "linux" ]; then
#     # detect linux sub-system on windows
#     if grep -q Microsoft /proc/version; then
#         plat="windows"
# 	bin_ext=".exe"
#     fi
# fi

bin_name=${bin_name}${bin_ext}

file=concourse_${plat}_${arch}${bin_ext}
bin=${bin_path}/${bin_name}
app=`basename $0`
cwd=`pwd -P`
dir=`dirname $(realpath $0)`

datetimestamp=`date "+%Y%m%d-%H%M%S"`

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

    # API based on https://concourse-ci.org version 3.14.1

    # Minimum level [debug|info|error|fatal] of logs to see. (default: info)
    #export CONCOURSE_LOG_LEVEL=

    # IP address on which to listen for web traffic. (default: 0.0.0.0)
    #export CONCOURSE_BIND_IP=

    # Port on which to listen for HTTP traffic. (default: 8080)
    #export CONCOURSE_BIND_PORT=

    # Set secure flag on auth cookies
    #export CONCOURSE_COOKIE_SECURE=

    # Port on which to listen for HTTPS traffic.
    #export CONCOURSE_TLS_BIND_PORT=

    # File containing an SSL certificate.
    #export CONCOURSE_TLS_CERT=

    # File containing an RSA private key, used to encrypt HTTPS traffic.
    #export CONCOURSE_TLS_KEY=

    # URL used to reach any ATC from the outside world.
    # (default: http://127.0.0.1:8080)
    export CONCOURSE_EXTERNAL_URL=$server_url

    # URL used to reach this ATC from other ATCs in the cluster.
    # (default: http://127.0.0.1:8080)
    #export CONCOURSE_PEER_URL=

    # Length of time for which tokens are valid.
    # Afterwards, users will have to log back in. (default: 24h)
    #export CONCOURSE_AUTH_DURATION=

    # URL used as the base of OAuth redirect URIs.
    # If not specified, the external URL is used.
    #export CONCOURSE_OAUTH_BASE_URL=

    # A 16 or 32 length key used to encrypt sensitive information
    # before storing it in the database.
    #export CONCOURSE_ENCRYPTION_KEY=

    # Encryption key previously used for encrypting sensitive information.
    # If provided without a new key, data is encrypted.
    # If provided with a new key, data is re-encrypted.
    #export CONCOURSE_OLD_ENCRYPTION_KEY=

    # IP address on which to listen for the pprof debugger endpoints.
    # (default: 127.0.0.1)
    #export CONCOURSE_DEBUG_BIND_IP=

    # Port on which to listen for the pprof debugger endpoints. (default: 8079)
    #export CONCOURSE_DEBUG_BIND_PORT=

    # File containing an RSA private key, used to sign session tokens.
    export CONCOURSE_SESSION_SIGNING_KEY=$server_key_signing_private

    # Length of time for a intercepted session to be idle before terminating.
    # (default: 0m)
    #export CONCOURSE_INTERCEPT_IDLE_TIMEOUT=

    # Interval on which to check for new versions of resources. (default: 1m)
    #export CONCOURSE_RESOURCE_CHECKING_INTERVAL=

    # Method by which a worker is selected during container placement.
    # (default: volume-locality)
    #export CONCOURSE_CONTAINER_PLACEMENT_STRATEGY=

    # How long to wait for Baggageclaim to send the response header.
    # (default: 1m)
    #export CONCOURSE_BAGGAGECLAIM_RESPONSE_HEADER_TIMEOUT=

    # Directory containing downloadable CLI binaries.
    #export CONCOURSE_CLI_ARTIFACTS_DIR=

    # Log database queries.
    if [ "$server_log_database_queries" == "true" ]; then
	export CONCOURSE_LOG_DB_QUERIES=1
    fi

    # Interval on which to run build tracking. (default: 10s)
    #export CONCOURSE_BUILD_TRACKER_INTERVAL=

    # Default build logs to retain, 0 means all
    #export CONCOURSE_DEFAULT_BUILD_LOGS_TO_RETAIN=

    # Maximum build logs to retain, 0 means not specified.
    # Will override values configured in jobs
    #export CONCOURSE_MAX_BUILD_LOGS_TO_RETAIN=

    # Print the current database version and exit
    #export CONCOURSE_CURRENT_DB_VERSION=

    # Print the max supported database version and exit
    #export CONCOURSE_SUPPORTED_DB_VERSION=

    # Migrate to the specified database version and exit
    #export CONCOURSE_MIGRATE_DB_TO_VERSION=

    # Username to use for basic auth.
    #export CONCOURSE_BASIC_AUTH_USERNAME=

    # Password to use for basic auth.
    #export CONCOURSE_BASIC_AUTH_PASSWORD=

    # Application client ID for enabling Bitbucket OAuth
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_CLIENT_ID=

    # Application client secret for enabling Bitbucket OAuth
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_CLIENT_SECRET=

    # Bitbucket users that are allowed to log in
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_USER=

    # Bitbucket teams which members are allowed to log in
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_TEAM=

    # Bitbucket repositories whose members are allowed to log in
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_REPOSITORY=

    # Override default endpoint AuthURL for Bitbucket Cloud
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_AUTH_URL=

    # Override default endpoint TokenURL for Bitbucket Cloud
    #export CONCOURSE_BITBUCKET_CLOUD_AUTH_TOKEN_URL=

    # Override default API endpoint URL for Bitbucket Cloud
    # Cloud [$CONCOURSE_BITBUCKET_CLOUD_AUTH_API_URL=

    # Application consumer key for enabling Bitbucket OAuth
    #export CONCOURSE_BITBUCKET_SERVER_AUTH_CONSUMER_KEY=

    # Path to application private key for enabling Bitbucket OAuth
    #export CONCOURSE_BITBUCKET_SERVER_AUTH_PRIVATE_KEY=

    # Endpoint for Bitbucket Server
    #export CONCOURSE_BITBUCKET_SERVER_AUTH_ENDPOINT=

    # Bitbucket users that are allowed to log in
    #export CONCOURSE_BITBUCKET_SERVER_AUTH_USER=

    # Bitbucket projects whose members are allowed to log in
    #export CONCOURSE_BITBUCKET_SERVER_AUTH_PROJECT=

    # Bitbucket repositories whose members are allowed to log in
    #export CONCOURSE_BITBUCKET_SERVER_AUTH_REPOSITORY=

    # Name for this auth method on the web UI.
    #export CONCOURSE_GENERIC_OAUTH_DISPLAY_NAME=

    # Application client ID for enabling generic OAuth.
    #export CONCOURSE_GENERIC_OAUTH_CLIENT_ID=

    # Application client secret for enabling generic OAuth.
    #export CONCOURSE_GENERIC_OAUTH_CLIENT_SECRET=

    # Generic OAuth provider AuthURL endpoint.
    #export CONCOURSE_GENERIC_OAUTH_AUTH_URL=

    # Parameter to pass to the authentication server AuthURL.
    # Can be specified multiple times.
    #export CONCOURSE_GENERIC_OAUTH_AUTH_URL_PARAM=

    # Optional scope required to authorize user
    #export CONCOURSE_GENERIC_OAUTH_SCOPE=

    # Generic OAuth provider TokenURL endpoint.
    #export CONCOURSE_GENERIC_OAUTH_TOKEN_URL=

    # PEM-encoded CA certificate string
    #export CONCOURSE_GENERIC_OAUTH_CA_CERT=

    # Ignore warnings about not configuring auth
    #export CONCOURSE_NO_REALLY_I_DONT_WANT_ANY_AUTH=

    # Application client ID for enabling UAA OAuth.
    #export CONCOURSE_UAA_AUTH_CLIENT_ID=

    # Application client secret for enabling UAA OAuth.
    #export CONCOURSE_UAA_AUTH_CLIENT_SECRET=

    # UAA AuthURL endpoint.
    #export CONCOURSE_UAA_AUTH_AUTH_URL=

    # UAA TokenURL endpoint.
    #export CONCOURSE_UAA_AUTH_TOKEN_URL=

    # Space GUID for a CF space whose developers will have access.
    #export CONCOURSE_UAA_AUTH_CF_SPACE=

    # CF API endpoint.
    #export CONCOURSE_UAA_AUTH_CF_URL=

    # Path to CF PEM-encoded CA certificate file.
    #export CONCOURSE_UAA_AUTH_CF_CA_CERT=

    # Name for this auth method on the web UI.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_DISPLAY_NAME=

    # Application client ID for enabling generic OAuth with OIDC.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_CLIENT_ID=

    # Application client secret for enabling generic OAuth with OIDC.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_CLIENT_SECRET=

    # UserID required to authorize user. Can be specified multiple times.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_USER_ID=

    # Groups required to authorize user. Can be specified multiple times.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_GROUPS=

    # Optional groups name to override default value returned by OIDC provider.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_CUSTOM_GROUPS_NAME=

    # Generic OAuth OIDC provider AuthURL endpoint.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_AUTH_URL=

    # Parameter to pass to the authentication server AuthURL.
    # Can be specified multiple times.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_AUTH_URL_PARAM=

    # Optional scope required to authorize user
    #export CONCOURSE_GENERIC_OAUTH_OIDC_SCOPE=

    # Generic OAuth OIDC provider TokenURL endpoint.
    #export CONCOURSE_GENERIC_OAUTH_OIDC_TOKEN_URL=

    # PEM-encoded CA certificate string
    #export CONCOURSE_GENERIC_OAUTH_OIDC_CA_CERT=

    # Application client ID for enabling GitHub OAuth.
    export CONCOURSE_GITHUB_AUTH_CLIENT_ID=$github_auth_client_id

    # Application client secret for enabling GitHub OAuth.
    export CONCOURSE_GITHUB_AUTH_CLIENT_SECRET=$github_auth_client_secret

    # GitHub organization whose members will have access.
    #export CONCOURSE_GITHUB_AUTH_ORGANIZATION=

    # GitHub team whose members will have access.
    #export CONCOURSE_GITHUB_AUTH_TEAM=

    # GitHub user to permit access.
    export CONCOURSE_GITHUB_AUTH_USER=$github_auth_user

    # Override default endpoint AuthURL for Github Enterprise.
    #export CONCOURSE_GITHUB_AUTH_AUTH_URL=

    # Override default endpoint TokenURL for Github Enterprise.
    #export CONCOURSE_GITHUB_AUTH_TOKEN_URL=

    # Override default API endpoint URL for Github Enterprise.
    #export CONCOURSE_GITHUB_AUTH_API_URL=

    # Application client ID for enabling GitLab OAuth.
    #export CONCOURSE_GITLAB_AUTH_CLIENT_ID=

    # Application client secret for enabling GitLab OAuth.
    #export CONCOURSE_GITLAB_AUTH_CLIENT_SECRET=

    # GitLab group whose members will have access.
    #export CONCOURSE_GITLAB_AUTH_GROUP=

    # Override default endpoint AuthURL for GitLab.
    #export CONCOURSE_GITLAB_AUTH_AUTH_URL=

    # Override default endpoint TokenURL for GitLab.
    #export CONCOURSE_GITLAB_AUTH_TOKEN_URL=

    # Override default API endpoint URL for GitLab.
    #export CONCOURSE_GITLAB_AUTH_API_URL=

    # PostgreSQL connection string.
    # (Deprecated; set the following flags instead.)
    #export CONCOURSE_POSTGRES_DATA_SOURCE=

    # The host to connect to. (default: 127.0.0.1)
    export CONCOURSE_POSTGRES_HOST=$server_postgres_addr

    # The port to connect to. (default: 5432)
    export CONCOURSE_POSTGRES_PORT=$server_postgres_port

    # Path to a UNIX domain socket to connect to.
    #export CONCOURSE_POSTGRES_SOCKET=

    # The user to sign in as.
    export CONCOURSE_POSTGRES_USER=$server_postgres_user

    # The user's password.
    export CONCOURSE_POSTGRES_PASSWORD=$server_postgres_pass

    # Whether or not to use SSL. (default: disable)
    #export CONCOURSE_POSTGRES_SSLMODE=

    # CA cert file location, to verify when connecting with SSL.
    #export CONCOURSE_POSTGRES_CA_CERT=

    # Client cert file location.
    #export CONCOURSE_POSTGRES_CLIENT_CERT=

    # Client key file location.
    #export CONCOURSE_POSTGRES_CLIENT_KEY=

    # Dialing timeout. (0 means wait indefinitely) (default: 5m)
    #export CONCOURSE_POSTGRES_CONNECT_TIMEOUT=

    # The name of the database to use. (default: atc)
    export CONCOURSE_POSTGRES_DATABASE=$server_postgres_data

    # CredHub server address used to access secrets.
    #export CONCOURSE_CREDHUB_URL=

    # Path under which to namespace credential lookup. (default: /concourse)
    #export CONCOURSE_CREDHUB_PATH_PREFIX=

    # Paths to PEM-encoded CA cert files to use to verify
    # the CredHub server SSL cert.
    #export CONCOURSE_CREDHUB_CA_CERT=

    # Path to the client certificate for mutual TLS authorization.
    #export CONCOURSE_CREDHUB_CLIENT_CERT=

    # Path to the client private key for mutual TLS authorization.
    #export CONCOURSE_CREDHUB_CLIENT_KEY=

    # Enable insecure SSL verification.
    #export CONCOURSE_CREDHUB_INSECURE_SKIP_VERIFY=

    # Client ID for CredHub authorization.
    #export CONCOURSE_CREDHUB_CLIENT_ID=

    # Client secret for CredHub authorization.
    #export CONCOURSE_CREDHUB_CLIENT_SECRET=

    # Enables the in-cluster client.
    #export CONCOURSE_KUBERNETES_IN_CLUSTER=

    # Path to Kubernetes config when running ATC outside Kubernetes.
    #export CONCOURSE_KUBERNETES_CONFIG_PATH=

    # Prefix to use for Kubernetes namespaces under which secrets
    # will be looked up. (default: concourse-)
    #export CONCOURSE_KUBERNETES_NAMESPACE_PREFIX=

    # AWS Access key ID
    #export CONCOURSE_AWS_SECRETSMANAGER_ACCESS_KEY=

    # AWS Secret Access Key
    #export CONCOURSE_AWS_SECRETSMANAGER_SECRET_KEY=

    # AWS Session Token
    #export CONCOURSE_AWS_SECRETSMANAGER_SESSION_TOKEN=

    # AWS region to send requests to
    #export AWS_REGION=

    # AWS Manager secret identifier template used for pipeline specific
    # parameter (default: /concourse/{{.Team}}/{{.Pipeline}}/{{.Secret}})
    #export CONCOURSE_AWS_SECRETSMANAGER_PIPELINE_SECRET_TEMPLATE=

    # AWS SSM Manager secret identifier  template used for team specific
    # parameter (default: /concourse/{{.Team}}/{{.Secret}})
    #export CONCOURSE_AWS_SECRETSMANAGER_TEAM_SECRET_TEMPLATE=

    # AWS Access key ID
    #export CONCOURSE_AWS_SSM_ACCESS_KEY=

    # AWS Secret Access Key
    #export CONCOURSE_AWS_SSM_SECRET_KEY=

    # AWS Session Token
    #export CONCOURSE_AWS_SSM_SESSION_TOKEN=

    # AWS region to send requests to
    #export AWS_REGION=

    # AWS SSM parameter name template used for pipeline specific parameter
    # (default: /concourse/{{.Team}}/{{.Pipeline}}/{{.Secret}})
    #export CONCOURSE_AWS_SSM_PIPELINE_SECRET_TEMPLATE=

    # AWS SSM parameter name template used for team specific parameter
    # (default: /concourse/{{.Team}}/{{.Secret}})
    #export CONCOURSE_AWS_SSM_TEAM_SECRET_TEMPLATE=

    # Vault server address used to access secrets.
    #export CONCOURSE_VAULT_URL=

    # Path under which to namespace credential lookup. (default: /concourse)
    #export CONCOURSE_VAULT_PATH_PREFIX=

    # If the cache is enabled, and this is set, override secrets
    # lease duration with a maximum value
    #export CONCOURSE_VAULT_MAX_LEASE=

    # Path to a PEM-encoded CA cert file to use to verify
    # the vault server SSL cert.
    #export CONCOURSE_VAULT_CA_CERT=

    # Path to a directory of PEM-encoded CA cert files to verify
    # the vault server SSL cert.
    #export CONCOURSE_VAULT_CA_PATH=

    # Path to the client certificate for Vault authorization.
    #export CONCOURSE_VAULT_CLIENT_CERT=

    # Path to the client private key for Vault authorization.
    #export CONCOURSE_VAULT_CLIENT_KEY=

    # If set, is used to set the SNI host when connecting via TLS.
    #export CONCOURSE_VAULT_SERVER_NAME=

    # Enable insecure SSL verification.
    #export CONCOURSE_VAULT_INSECURE_SKIP_VERIFY=

    # Client token for accessing secrets within the Vault server.
    #export CONCOURSE_VAULT_CLIENT_TOKEN=

    # Auth backend to use for logging in to Vault.
    #export CONCOURSE_VAULT_AUTH_BACKEND=

    # Time after which to force a re-login.
    # If not set, the token will just be continuously renewed.
    #export CONCOURSE_VAULT_AUTH_BACKEND_MAX_TTL=

    # The maximum time between retries when logging in or re-authing a secret.
    # (default: 5m)
    #export CONCOURSE_VAULT_RETRY_MAX=

    # The initial time between retries when logging in or re-authing a secret.
    # (default: 1s)
    #export CONCOURSE_VAULT_RETRY_INITIAL=

    # Paramter to pass when logging in via the backend.
    # Can be specified multiple times.
    #export CONCOURSE_VAULT_AUTH_PARAM=

    # Don't actually do any automatic scheduling or checking.
    #export CONCOURSE_NOOP=

    # A Garden API endpoint to register as a worker.
    #export CONCOURSE_WORKER_GARDEN_URL=

    # A Baggageclaim API endpoint to register with the worker.
    #export CONCOURSE_WORKER_BAGGAGECLAIM_URL=

    # A resource type to advertise for the worker.
    # Can be specified multiple times.
    #export CONCOURSE_WORKER_RESOURCE=

    # Host string to attach to emitted metrics.
    #export CONCOURSE_METRICS_HOST_NAME=

    # A key-value attribute to attach to emitted metrics.
    # Can be specified multiple times.
    #export CONCOURSE_METRICS_ATTRIBUTE=

    # Yeller API key. If specified, all errors logged will be emitted.
    #export CONCOURSE_YELLER_API_KEY=

    # Environment to tag on all Yeller events emitted.
    #export CONCOURSE_YELLER_ENVIRONMENT=

    # Datadog agent host to expose dogstatsd metrics
    #export CONCOURSE_DATADOG_AGENT_HOST=

    # Datadog agent port to expose dogstatsd metrics
    #export CONCOURSE_DATADOG_AGENT_PORT=

    # Prefix for all metrics to easily find them in Datadog
    #export CONCOURSE_DATADOG_PREFIX=

    # InfluxDB server address to emit points to.
    #export CONCOURSE_INFLUXDB_URL=

    # InfluxDB database to write points to.
    #export CONCOURSE_INFLUXDB_DATABASE=

    # InfluxDB server username.
    #export CONCOURSE_INFLUXDB_USERNAME=

    # InfluxDB server password.
    #export CONCOURSE_INFLUXDB_PASSWORD=

    # Skip SSL verification when emitting to InfluxDB.
    #export CONCOURSE_INFLUXDB_INSECURE_SKIP_VERIFY=

    # Emit metrics to logs.
    #export CONCOURSE_EMIT_TO_LOGS=

    # New Relic Account ID
    #export CONCOURSE_NEWRELIC_ACCOUNT_ID=

    # New Relic Insights API Key
    #export CONCOURSE_NEWRELIC_API_KEY=

    # An optional prefix for emitted New Relic events
    #export CONCOURSE_NEWRELIC_SERVICE_PREFIX=

    # IP to listen on to expose Prometheus metrics.
    #export CONCOURSE_PROMETHEUS_BIND_IP=

    # Port to listen on to expose Prometheus metrics.
    #export CONCOURSE_PROMETHEUS_BIND_PORT=

    # Riemann server address to emit metrics to.
    #export CONCOURSE_RIEMANN_HOST=

    # Port of the Riemann server to emit metrics to. (default: 5555)
    #export CONCOURSE_RIEMANN_PORT=

    # An optional prefix for emitted Riemann services
    #export CONCOURSE_RIEMANN_SERVICE_PREFIX=

    # Tag to attach to emitted metrics.
    # Can be specified multiple times.
    #export CONCOURSE_RIEMANN_TAG=

    # The value to set for X-Frame-Options. If omitted, the header is not set.
    #export CONCOURSE_X_FRAME_OPTIONS=

    # Interval on which to perform garbage collection. (default: 30s)
    #export CONCOURSE_GC_INTERVAL=

    # Maximum number of delete operations to have in flight per worker.
    # (default: 50)
    #export CONCOURSE_GC_WORKER_CONCURRENCY=

    # Minimum level of logs to see. (default: info)
    #export CONCOURSE_TSA_LOG_LEVEL=

    # IP address on which to listen for SSH. (default: 0.0.0.0)
    #export CONCOURSE_TSA_BIND_IP=

    # Port on which to listen for SSH. (default: 2222)
    #export CONCOURSE_TSA_BIND_PORT=

    # Port on which to listen for TSA pprof server. (default: 8089)
    #export CONCOURSE_TSA_BIND_DEBUG_PORT=

    # IP address of this TSA, reachable by the ATCs. Used for forwarded worker
    # addresses.
    #export CONCOURSE_TSA_PEER_IP=

    # Path to private key to use for the SSH server.
    export CONCOURSE_TSA_HOST_KEY=$server_key_private

    # Path to file containing keys to authorize, in SSH authorized_keys format
    # (one public key per line).
    export CONCOURSE_TSA_AUTHORIZED_KEYS=$server_key_authorized_workers

    # Path to file containing keys to authorize, in SSH authorized_keys format
    # (one public key per line).
    #export CONCOURSE_TSA_TEAM_AUTHORIZED_KEYS=

    # ATC API endpoints to which workers will be registered.
    #export CONCOURSE_TSA_ATC_URL=

    # Path to private key to use when signing tokens in reqests to the
    # ATC during registration.
    #export CONCOURSE_TSA_SESSION_SIGNING_KEY=

    # interval on which to heartbeat workers to the ATC (default: 30s)
    #export CONCOURSE_TSA_HEARTBEAT_INTERVAL=

    # Yeller API key. If specified, all errors logged will be emitted.
    #export CONCOURSE_TSA_YELLER_API_KEY=

    # Environment to tag on all Yeller events emitted.
    #export CONCOURSE_TSA_YELLER_ENVIRONMENT]
    
    message "starting concourse server"
    execute web
}

function worker
{
    check_if_bin_exists_else_fetch_it
    mkdir -p $worker_dir

    local name=$worker_name.$datetimestamp
    echo "$name" > $worker_dir/.name

    # API based on https://concourse-ci.org version 3.14.1

    # The name to set for the worker during registration.
    # If not specified, the hostname will be used.
    export CONCOURSE_NAME=$name

    # A tag to set during registration. Can be specified multiple times.
    #export CONCOURSE_TAG=

    # The name of the team that this worker will be assigned to.
    #export CONCOURSE_TEAM=

    # HTTP proxy endpoint to use for containers.
    #export http_proxy=

    # HTTPS proxy endpoint to use for containers.
    #export https_proxy=

    # Blacklist of addresses to skip the proxy when reaching.
    #export no_proxy=

    # Port on which to listen for beacon pprof server. (default: 9099)
    #export CONCOURSE_BIND_DEBUG_PORT=

    # Directory to use when creating the resource certificates volume.
    #export CONCOURSE_CERTS_DIR=

    # Directory in which to place container data.
    export CONCOURSE_WORK_DIR=$worker_dir

    # IP address on which to listen for the Garden server. (default: 127.0.0.1)
    #export CONCOURSE_BIND_IP=

    # Port on which to listen for the Garden server. (default: 7777)
    #export CONCOURSE_BIND_PORT=

    # IP used to reach this worker from the ATC nodes.
    #export CONCOURSE_PEER_IP=

    # Minimum level [debug|info|error|fatal] of logs to see. (default: info)
    #export CONCOURSE_LOG_LEVEL=

    # TSA host to forward the worker through.
    # Can be specified multiple times. (default: 127.0.0.1:2222)
    export CONCOURSE_TSA_HOST=$server_addr:$server_port

    # File containing a public key to expect from the TSA.
    export CONCOURSE_TSA_PUBLIC_KEY=$server_key_public

    # File containing the private key to use when authenticating to the TSA.
    export CONCOURSE_TSA_WORKER_PRIVATE_KEY=$worker_key_private

    # Minimum level of logs to see. (default: info)
    #export CONCOURSE_GARDEN_LOG_LEVEL=

    # Format of log timestamps. (default: unix-epoch)
    #export CONCOURSE_GARDEN_TIME_FORMAT=

    # Bind with TCP on the given IP.
    #export CONCOURSE_GARDEN_BIND_IP=

    # Bind with TCP on the given port. (default: 7777)
    #export CONCOURSE_GARDEN_BIND_PORT=

    # Bind with Unix on the given socket path. (default: /tmp/garden.sock)
    #export CONCOURSE_GARDEN_BIND_SOCKET=

    # Bind the debug server on the given IP.
    #export CONCOURSE_GARDEN_DEBUG_BIND_IP=

    # Bind the debug server to the given port. (default: 17013)
    #export CONCOURSE_GARDEN_DEBUG_BIND_PORT=

    # Skip the preparation part of the host that requires root privileges
    #export CONCOURSE_GARDEN_SKIP_SETUP=

    # Directory in which to store container data. (default: /var/run/gdn/depot)
    #export CONCOURSE_GARDEN_DEPOT=

    # Path in which to store properties.
    #export CONCOURSE_GARDEN_PROPERTIES_PATH=

    # Path in which to store temporary sockets
    #export CONCOURSE_GARDEN_CONSOLE_SOCKETS_PATH=

    # Clean up proccess dirs on first invocation of wait
    #export CONCOURSE_GARDEN_CLEANUP_PROCESS_DIRS_ON_WAIT=

    # Disable creation of privileged containers
    #export CONCOURSE_GARDEN_DISABLE_PRIVILEGED_CONTAINERS=

    # The lowest numerical subordinate user ID the user
    # is allowed to map (default: 1)
    #export CONCOURSE_GARDEN_UID_MAP_START=

    # The number of numerical subordinate user IDs the user is allowed to map
    #export CONCOURSE_GARDEN_UID_MAP_LENGTH=

    # The lowest numerical subordinate group ID the user is allowed to map
    # default: 1)
    #export CONCOURSE_GARDEN_GID_MAP_START=

    # The number of numerical subordinate group IDs the user is allowed to map
    #export CONCOURSE_GARDEN_GID_MAP_LENGTH=

    # Default rootfs to use when not specified on container creation.
    #export CONCOURSE_GARDEN_DEFAULT_ROOTFS=

    # Default time after which idle containers should expire.
    #export CONCOURSE_GARDEN_DEFAULT_GRACE_TIME=

    # Clean up all the existing containers on startup.
    #export CONCOURSE_GARDEN_DESTROY_CONTAINERS_ON_STARTUP=

    # Apparmor profile to use for unprivileged container processes
    #export CONCOURSE_GARDEN_APPARMOR=

    # Directory in which to extract packaged assets (default: /var/gdn/assets)
    #export CONCOURSE_GARDEN_ASSETS_DIR=

    # Path to the 'dadoo' binary.
    #export CONCOURSE_GARDEN_DADOO_BIN=

    # Path to the 'nstar' binary.
    #export CONCOURSE_GARDEN_NSTAR_BIN=

    # Path to the 'tar' binary.
    #export CONCOURSE_GARDEN_TAR_BIN=

    # path to the iptables binary (default: /sbin/iptables)
    #export CONCOURSE_GARDEN_IPTABLES_BIN=

    # path to the iptables-restore binary (default: /sbin/iptables-restore)
    #export CONCOURSE_GARDEN_IPTABLES_RESTORE_BIN=

    # Path execute as pid 1 inside each container.
    #export CONCOURSE_GARDEN_INIT_BIN=

    # Path to the runtime plugin binary. (default: runc)
    #export CONCOURSE_GARDEN_RUNTIME_PLUGIN=

    # Extra argument to pass to the runtime plugin.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_RUNTIME_PLUGIN_EXTRA_ARG=

    # Directory on which to store imported rootfs graph data.
    #export CONCOURSE_GARDEN_GRAPH=

    # Disk usage of the graph dir at which cleanup should trigger,
    # or -1 to disable graph cleanup. (default: -1)
    #export CONCOURSE_GARDEN_GRAPH_CLEANUP_THRESHOLD_IN_MEGABYTES=

    # Image that should never be garbage collected.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_PERSISTENT_IMAGE=

    # Path to image plugin binary.
    #export CONCOURSE_GARDEN_IMAGE_PLUGIN=

    # Extra argument to pass to the image plugin to create unprivileged images.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_IMAGE_PLUGIN_EXTRA_ARG=

    # Path to privileged image plugin binary.
    #export CONCOURSE_GARDEN_PRIVILEGED_IMAGE_PLUGIN=

    # Extra argument to pass to the image plugin to create privileged images.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_PRIVILEGED_IMAGE_PLUGIN_EXTRA_ARG=

    # Docker registry API endpoint. (default: registry-1.docker.io)
    #export CONCOURSE_GARDEN_DOCKER_REGISTRY=

    # Docker registry to allow connecting to even if not secure.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_INSECURE_DOCKER_REGISTRY=

    # Network range to use for dynamically allocated container subnets.
    # (default: 10.254.0.0/22)
    #export CONCOURSE_GARDEN_NETWORK_POOL=

    # Allow network access to the host machine.
    #export CONCOURSE_GARDEN_ALLOW_HOST_ACCESS=

    # Network ranges to which traffic from containers will be denied.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_DENY_NETWORK=

    # DNS server IP address to use instead of automatically determined servers.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_DNS_SERVER=

    # DNS server IP address to append to the automatically determined servers.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_ADDITIONAL_DNS_SERVER=

    # Per line hosts entries. Can be specified multiple times and will be
    # appended verbatim in order to /etc/hosts
    #export CONCOURSE_GARDEN_ADDITIONAL_HOST_ENTRY=

    # IP address to use to reach container's mapped ports.
    # Autodetected if not specified.
    #export CONCOURSE_GARDEN_EXTERNAL_IP=

    # Start of the ephemeral port range used for mapped container ports.
    # (default: 61001)
    #export CONCOURSE_GARDEN_PORT_POOL_START=

    # Size of the port pool used for mapped container ports. (default: 4534)
    #export CONCOURSE_GARDEN_PORT_POOL_SIZE=

    # Path in which to store port pool properties.
    #export CONCOURSE_GARDEN_PORT_POOL_PROPERTIES_PATH=

    # MTU size for container network interfaces.
    # Defaults to the MTU of the interface used for outbound access by the host.
    # Max allowed value is 1500.
    #export CONCOURSE_GARDEN_MTU=

    # Path to network plugin binary.
    #export CONCOURSE_GARDEN_NETWORK_PLUGIN=

    # Extra argument to pass to the network plugin.
    # Can be specified multiple times.
    #export CONCOURSE_GARDEN_NETWORK_PLUGIN_EXTRA_ARG=

    # Maximum number of microseconds each cpu share assigned to a container
    # allows per quota period (default: 0)
    #export CONCOURSE_GARDEN_CPU_QUOTA_PER_SHARE=

    # Export hard limit for the tcp buf memory, value in bytes (default: 0)
    #export CONCOURSE_GARDEN_TCP_MEMORY_LIMIT=

    # Default block IO weight assigned to a container (default: 0)
    #export CONCOURSE_GARDEN_DEFAULT_CONTAINER_BLOCKIO_WEIGHT=

    # Maximum number of containers that can be created. (default: 0)
    #export CONCOURSE_GARDEN_MAX_CONTAINERS=

    # Disable swap memory limit
    #export CONCOURSE_GARDEN_DISABLE_SWAP_LIMIT=

    # Interval on which to emit metrics. (default: 1m)
    #export CONCOURSE_GARDEN_METRICS_EMISSION_INTERVAL=

    # Origin identifier for Dropsonde-emitted metrics. (default: garden-linux)
    #export CONCOURSE_GARDEN_DROPSONDE_ORIGIN=

    # Destination for Dropsonde-emitted metrics. (default: 127.0.0.1:3457)
    #export CONCOURSE_GARDEN_DROPSONDE_DESTINATION=

    # Path to a containerd socket.
    #export CONCOURSE_GARDEN_CONTAINERD_SOCKET=

    # Enable proxy DNS server.
    #export CONCOURSE_GARDEN_DNS_PROXY_ENABLE=

    # Minimum level of logs to see. (default: info)
    #export CONCOURSE_BAGGAGECLAIM_LOG_LEVEL=

    # IP address on which to listen for API traffic. (default: 127.0.0.1)
    #export CONCOURSE_BAGGAGECLAIM_BIND_IP=

    # Port on which to listen for API traffic. (default: 7788)
    #export CONCOURSE_BAGGAGECLAIM_BIND_PORT=

    # Port on which to listen for baggageclaim pprof server. (default: 8099)
    #export CONCOURSE_BAGGAGECLAIM_BIND_DEBUG_PORT=

    # Directory in which to place volume data.
    #export CONCOURSE_BAGGAGECLAIM_VOLUMES=

    # Driver to use for managing volumes. (default: detect)
    #export CONCOURSE_BAGGAGECLAIM_DRIVER=

    # Path to btrfs binary (default: btrfs)
    #export CONCOURSE_BAGGAGECLAIM_BTRFS_BIN=

    # Path to mkfs.btrfs binary (default: mkfs.btrfs)
    #export CONCOURSE_BAGGAGECLAIM_MKFS_BIN=

    # Path to directory in which to store overlay data
    #export CONCOURSE_BAGGAGECLAIM_OVERLAYS_DIR=

    # Interval on which to reap expired volumes. (default: 10s)
    #export CONCOURSE_BAGGAGECLAIM_REAP_INTERVAL=

    # Yeller API key. If specified, all errors logged will be emitted.
    #export CONCOURSE_BAGGAGECLAIM_YELLER_API_KEY=

    # Environment to tag on all Yeller events emitted.
    #export CONCOURSE_BAGGAGECLAIM_YELLER_ENVIRONMENT=

    # Yeller API key. If specified, all errors logged will be emitted.
    #export CONCOURSE_YELLER_API_KEY=

    # Environment to tag on all Yeller events emitted.
    #export CONCOURSE_YELLER_ENVIRONMENT=

    message "starting concourse worker '$name'"
    execute worker
}

function retire
{
    check_if_bin_exists_else_fetch_it

    if stat $worker_dir/.name; then
	error "no worker has been started yet"
	return
    fi

    local name=`cat ${worker_dir}/.name`

    # API based on https://concourse-ci.org version 3.14.1
    # 'retire' equals 'land'

    # The name of the worker you wish to retire.
    export CONCOURSE_NAME=$name

    # TSA host to forward the worker through. Can be specified
    # multiple times. (default: 127.0.0.1:2222)
    export CONCOURSE_TSA_HOST=$server_addr:$server_port

    # File containing a public key to expect from the TSA.
    export CONCOURSE_TSA_PUBLIC_KEY=$server_key_public

    # File containing the private key to use when authenticating to the TSA.
    export CONCOURSE_TSA_WORKER_PRIVATE_KEY=$worker_key_private

    if [ "$1" == "land" ]; then
	message "landing concourse worker '$name'"
	execute land-worker
    else
	message "retiring concourse worker '$name'"
	execute retire-worker
    fi
}

function execute
{
    if [ "${plat}" != "windows" ]; then
	$bin $1
    else
	local clean_env=`env | grep CONCOURSE`
	clean_env=`echo $clean_env | tr '\n' "&" | sed "s/&/ & set /g"`
	(cd ${bin_path}; cmd.exe /c "set ${clean_env} & ${bin_name} $1")
    fi
}

function start
{
    if [ "${plat}" == "linux" ]; then
	iptables -I FORWARD -j ACCEPT
    fi

    worker
}

function stop
{
    retire

    if [ "${plat}" != "windows" ]; then
	sleep 5
    else
	cmd.exe /c timeout 5 > nul
    fi

    if [ "${plat}" != "windows" ]; then
	/sbin/reboot
    else
	cmd.exe /c shutdown /r /t 0
    fi
}

if [ "$dir" != "$cwd" ]; then
    error "$app has to be executed inside its root directory!"
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

main $*

# cd jq
# autoreconf -i
# ./configure --disable-maintainer-mode
# make
