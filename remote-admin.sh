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
# Command
# ----------------------------------------

#function _mysqlstore(){
#    . ./admin-agent.sh
#    set_wp_path ../../
#	local db_name=$(get_wp_config_value DB_NAME)
#	local db_user=$(get_wp_config_value DB_USER)
#	local db_password=$(get_wp_config_value DB_PASSWORD)
#	local db_host=$(get_wp_config_value DB_HOST)
#	echo ${db_name}
#	echo ${db_user}
#	echo ${db_password}
#	echo ${db_host}
#}

function _dump() {
    __mysqldump $@
}

function __mysqldump() {
    if [ -f $(cd $(dirname $0);pwd)/.env ]; then
        . $(cd $(dirname $0);pwd)/.env
    else
        echo "error: .env file does not exist."
        exit 1
    fi

    if [ ! -z $1 ]; then
        download_dump_file=$1
    else
        download_dump_file=$(cd $(dirname $0);pwd)/sql/dump.sql.tar.gz
    fi

    agent_path=${wp_root}/wp-sync
    dump_file=${agent_path}/sql/dump.sql
    
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
    
    # DUMP MYSQL DATA
    if [ ! -z ${wp_host} ]; then
        ssh ${wp_host} sh ${agent_path}/admin-agent.sh dump true || {
            echo "error."
            exit 1
        }
    else
        ssh -p ${ssh_port} ${ssh_user}@${ssh_host} sh ${agent_path}/admin-agent.sh dump true || {
            echo "error."
            exit 1
        }
    fi

    # DOWNLOAD DUMP DATA
    echo ">>> download dump data..."
    mkdir -p $(cd $(dirname $0);pwd)/sql

    if [ ! -z ${wp_host} ]; then
        scp ${wp_host}:${dump_file}.tar.gz ${download_dump_file} || {
            echo "error."
            exit 1
        }
    else
        scp -P ${ssh_port} ${ssh_user}@${ssh_host}:${dump_file}.tar.gz ${download_dump_file} || {
            echo "error."
            exit 1
        }
    fi
    
    # CLEAN UP
    echo ">>> clean up..."
    if [ ! -z ${wp_host} ]; then
        #ssh -t -t x <<EOF
        ssh x <<EOF > /dev/null 2>&1
rm -rf ${agent_path}/admin-agent.sh
rm -rf ${dump_file}.tar.gz
rm -rf ${dump_file}
exit
EOF
    else
        ssh -p ${ssh_port} ${ssh_user}@${ssh_host} <<EOF > /dev/null 2>&1
rm -rf ${agent_path}/admin-agent.sh
rm -rf ${dump_file}.tar.gz
rm -rf ${dump_file}
exit
EOF
    fi
    
    echo "complete!"
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
if [ $# -eq 0 ]; then
    echo "error: invalid argument(s)"
    echo "See '${project_name} -h'." 
    exit 1
fi

# execute command
if __is_executable _$1; then
    cmd=$1; shift
    _${cmd} $@
else
    echo "error: not executable."
    echo "See '${project_name} -h'." 
    exit 1
fi

exit 0

