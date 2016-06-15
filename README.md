# wp-sync

The wp-sync is an utility script easy to obtain remote backup of the WordPress files and DB dump data. 

## Installation

git clone ``wp-sync`` to directory you want.

```bash
$ mkdir workdir && cd workdir
$ git clone clone git clone https://github.com/ontheroadjp/wp-sync.git
```

## Usage

### 1. Modify .env file

Copy ``.env.sample`` to create ``.env`` file and modify ``.env`` as your environment.

```bash
$ cd wp-cync
$ cp .env.sample .env
```

|key|value|
|:---|:---|
|wp_host|WordPress server host name defiend in ``~/.ssh/config``|
|wp_root|WordPress install directry of remote server in full path |

**example**

if ``~/.ssh/config`` is

```vim
Host mywpserver
	HostName xxx.xxx.xxx.xxx
	Port 22
	User nobita
```

``wp-sync/.env`` is

```vim
wp_host="mywpserver"
wp_root="/home/nobita/example.jp/public_html/blog"
```

### 2. Exec command

```bash
$ sh remote-admin.sh dump				# dump all data
$ sh remote-admin.sh mysqldump			# dump only DB data
$ sh remote-admin.sh wordpressdump 	# dump only WordPress files
```

* After execute one of the remote-admin command, dump data you specify will be downloaded into ``wp-sync/data`` directory
