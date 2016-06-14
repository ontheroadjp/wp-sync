#!/bin/sh

# ----------------------------------------
# Global variables
# ----------------------------------------

project_name="wpsync"
project_name=$0
version="0.1"

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
    dump            Obtaining MySQL dump data

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
# Global variable
# ----------------------------------------

agent_path=""
remote_data_dir=""
local_data_dir=""

# ----------------------------------------
# Command
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
    local_data_dir=$(cd $(dirname $0);pwd)/data
    mkdir -p ${local_data_dir}

    # UPLOAD admin-agent.sh
    echo ">>> upload admin-agent.sh..."
    if [ ! -z ${wp_host} ]; then
        ssh ${wp_host} mkdir -p ${agent_path}
        scp $(cd $(dirname $0);pwd)/admin-agent.sh ${wp_host}:${agent_path}/admin-agent.sh || {
            echo "error."
            exit 1
        }
    else
        ssh -p ${ssh_port} ${ssh_user}@${ssh_host} mkdir -p ${agent_path}
        scp -P ${ssh_port} $(cd $(dirname $0);pwd)/admin-agent.sh ${ssh_user}@${ssh_host}:${agent_path}/admin-agent.sh || {
            echo "error."
            exit 1
        }
    fi
}

function __download_data() {
    echo ">>> download data..."

    if [ ! -z ${wp_host} ]; then
        scp -r ${wp_host}:${remote_data_dir} ${local_data_dir} || {
            echo "error."
            exit 1
        }
    else
        scp -r -P ${ssh_port} ${ssh_user}@${ssh_host}:${remote_data_dir} ${local_data_dir} || {
            echo "error."
            exit 1
        }
    fi
    
}

#function __clean_up() {
#    echo ">>> clean up..."
#    if [ ! -z ${wp_host} ]; then
#        ssh x <<EOF > /dev/null 2>&1
#rm -rf ${agent_path}/admin-agent.sh
#rm -rf ${remote_data_dir}
#exit
#EOF
#    else
#        ssh -p ${ssh_port} ${ssh_user}@${ssh_host} <<EOF > /dev/null 2>&1
#rm -rf ${agent_path}/admin-agent.sh
#rm -rf ${remote_data_dir}
#exit
#EOF
#    fi
#}

# ----------------------------------------
# Command
# ----------------------------------------

function _dump() {
    _mysqldump
    _wordpressdump
}

function _mysqldump() {

    # DUMP MYSQL DATA
    if [ ! -z ${wp_host} ]; then
        ssh ${wp_host} sh ${agent_path}/admin-agent.sh mysqldump true || {
            echo "error."
            exit 1
        }
    else
        ssh -p ${ssh_port} ${ssh_user}@${ssh_host} sh ${agent_path}/admin-agent.sh mysqldump true || {
            echo "error."
            exit 1
        }
    fi
}

function _wordpressdump() {

    # DUMP MYSQL DATA
    if [ ! -z ${wp_host} ]; then
        ssh ${wp_host} sh ${agent_path}/admin-agent.sh wordpressdump || {
            echo "error."
            exit 1
        }
    else
        ssh -p ${ssh_port} ${ssh_user}@${ssh_host} sh ${agent_path}/admin-agent.sh wordpressdump || {
            echo "error."
            exit 1
        }
    fi
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
                #__clean_up && {
                    echo "complete!"
                #}
            }
        }
    }
else
    echo "error: not executable."
    echo "See '${project_name} -h'." 
    exit 1
fi

exit 0
