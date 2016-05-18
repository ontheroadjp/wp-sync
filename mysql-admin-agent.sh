#!/bin/sh

version="0.1"
project_name=$0

self_path=$(cd $(dirname $0);pwd)
dump_dir=${self_path}/sql
dump_file_name="dump.sql"

function __usage() {
  cat <<-EOF
Usage: 
    ${project_name} <command>
    ${project_name} [-v|-h]

option:
    -v              Show the version of ${project_name}
    -h              Show this message

command:
    dump            Dump mysql data

EOF
}

function __version() { 
    echo ${version} 
}

function __help() { 
    __usage 
}

function __is_executable() {
    local command="$1"
    type "${command}" > /dev/null 2>&1
}

function __get_wp_config_value() {
	if [ $# -ne 1 ]; then
		echo "error: invalid argument(s)."
		exit 1
	fi
	
	cat ${self_path}/../wp-config.php | grep "'$1'" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "error: there is no key: $1."
		exit 1
	fi

	value=$(cat ${self_path}/../wp-config.php | \
		grep "'$1'" | \
		sed -e "s/^define(.*'$1',[ |]//" | \
		sed -e "s/);.*$//" | \
		sed -e "s/^'//" | \
		sed -e "s/'$//")

	echo ${value}
}

function _set_self_path() {
    self_path=$1
}

function _dump() {
	mkdir -p ${dump_dir}

	local db_name=$(__get_wp_config_value DB_NAME)
	local db_user=$(__get_wp_config_value DB_USER)
	local db_password=$(__get_wp_config_value DB_PASSWORD)
	local db_host=$(__get_wp_config_value DB_HOST)

	mysqldump --single-transaction \
		-h ${db_host} \
		-u ${db_user} \
		-p${db_password} ${db_name} > ${dump_dir}/${dump_file_name}

    if [ $# -ne 0 ] && [ $1 = "true" ]; then
        tar cvzf ${dump_dir}/${dump_file_name}.tar.gz -C ${dump_dir} ${dump_file_name} > /dev/null 2>&1
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
    echo "error: invalid argument(s)"
    echo "See '${project_name} -h'." 
    exit 1
fi

exit 0
