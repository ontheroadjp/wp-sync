#!/bin/sh

version="0.1"
project_name=$0

self_path=$(cd $(dirname $0);pwd)
dump_dir=${self_path}/data

function __usage() {
  cat <<-EOF
Usage: 
    ${project_name} <command>
    ${project_name} [-v|-h]

option:
    -v              Show the version of ${project_name}
    -h              Show this message

command:
    dump            Dump all data
    mysqldump       Dump only mysql data
    wordpressdump   Dump only wordpress data

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

# ----------------------------------------
# Commands
# ----------------------------------------

function _mysqldump() {
	mkdir -p ${dump_dir}

	local db_name=$(__get_wp_config_value DB_NAME)
	local db_user=$(__get_wp_config_value DB_USER)
	local db_password=$(__get_wp_config_value DB_PASSWORD)
	local db_host=$(__get_wp_config_value DB_HOST)

    local db_engine="innodb"

    if [ ${db_engine} = "innodb" ]; then
	    mysqldump --quote-names \
            --skip-lock-tables \
            --single-transaction \
	    	-h ${db_host} \
	    	-u ${db_user} \
	    	-p${db_password} ${db_name} > ${dump_dir}/${db_name}.sql
    elif [ ${db_engine} = "myisam" ]; then
        mysqldump --quote-names \
	    	-h ${db_host} \
	    	-u ${db_user} \
	    	-p${db_password} ${db_name} > ${dump_dir}/${db_name}.sql
    fi

    if [ $# -ne 0 ] && [ $1 = "true" ] && [ -f ${dump_dir}/${db_name}.sql ]; then
        gzip -r -f ${dump_dir}/${db_name}.sql
    fi
}

function _wordpressdump() {
	mkdir -p ${dump_dir}
    tar cvzf ${dump_dir}/wp.tar.gz ${self_path}/../ --exclude wp-sync/
}

function _dump() {
    _mysqldump $@
    _wordpressdump $@
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

# check wp-config.php
if [ ! -f ${self_path}/../wp-config.php ]; then
    echo "error: wp-config.php doesn't exist."
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
