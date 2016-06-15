#!/bin/sh

# ----------------------------------------
# Global variables
# ----------------------------------------

project_name="wpsync"
project_name=$0
version="1.0.0"

# ----------------------------------------
# Private Functions
# ----------------------------------------

function __usage() {
  cat <<-EOF
Usage: 
    ${project_name} <command>

option:
    -v              Show the version of ${project_name}
    -h              Show this message

command:
    dump            Dump all data
    mysqldump       Dump only mysql data
    wordpressdump   Dump only wordpress data

EOF
}

function __is_executable() {
    local command="$1"
    type "${command}" > /dev/null 2>&1
}

function __version() { 
    echo ${version} 
}

function __help() { 
    __usage 
}

# ----------------------------------------
# Global variables
# ----------------------------------------

agent_path=""
remote_data_dir=""
local_data_dir=""

# ----------------------------------------
# Functions
# ----------------------------------------

function __init() {

    # Load .env file
    if [ -f $(cd $(dirname $0);pwd)/.env ]; then
        . $(cd $(dirname $0);pwd)/.env
    else
        echo "error: .env file does not exist."
        exit 1
    fi

    # Initialize
    agent_path=${wp_root}/wp-sync
    remote_data_dir=${agent_path}/data
    local_data_dir=$(cd $(dirname $0);pwd)
    mkdir -p ${local_data_dir}

    # UPLOAD admin-agent.sh
    echo ">>> upload admin-agent.sh..."
    ssh ${wp_host} mkdir -p ${agent_path}
    scp $(cd $(dirname $0);pwd)/admin-agent.sh ${wp_host}:${agent_path}/admin-agent.sh || {
        echo "error."
        exit 1
    }
}

function __download_data() {
    echo ">>> download data..."

    scp -r ${wp_host}:${remote_data_dir} ${local_data_dir} || {
        echo "error."
        exit 1
    }
}

function __clean_up() {
    echo ">>> clean up..."
        ssh x <<EOF > /dev/null 2>&1
rm -rf ${agent_path}
EOF
}

# ----------------------------------------
# Commands
# ----------------------------------------

function _dump() {
    _mysqldump
    _wordpressdump
}

function _mysqldump() {
    ssh ${wp_host} sh ${agent_path}/admin-agent.sh mysqldump true || {
        echo "error."
        exit 1
    }
}

function _wordpressdump() {
    ssh ${wp_host} sh ${agent_path}/admin-agent.sh wordpressdump || {
        echo "error."
        exit 1
    }
}

# ----------------------------------------
# Main Routine
# ----------------------------------------

# check option(s)
while getopts hv OPT
do
  case $OPT in
    "h" ) __help;exit 0 ;;
    "v" ) __version;exit 0 ;;
  esac
done
shift $(expr $OPTIND - 1)

# check argument(s)
if [ $# -ne 1 ]; then
    echo "error: invalid argument(s)"
    echo "See '${project_name} -h'." 
    exit 1
fi

# execute command
if __is_executable _$1; then
    cmd=$1; shift

    __init && {
        _${cmd} && {
            __download_data && {
                __clean_up && {
                    echo "complete!"
                }
            }
        }
    }
else
    echo "error: not executable."
    echo "See '${project_name} -h'." 
    exit 1
fi

exit 0
