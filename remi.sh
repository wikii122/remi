#!/bin/bash
USAGE="
Remi - simple script used for delayed file removal.\n
Usage:\n
\tremi filename [filename, ...]\n
\tremi OPTION [filename]\n
Help:\n
\tfilename - passing only filename moves file to trash directory.\n
Options\n
\t--list - list all deleted files from this directory.\n
\t--list-all - list all deleted files.\n
\t--revert filename [version] - bring back file of given name to current directory. If more than one exists, version is required.\n
"

if [[ $# -lt 1 ]]
then
	echo -e $USAGE
	exit 1
fi

OPTION=$1
case $OPTION in
	"--list") 
		awk -v path=$(readlink -f $PWD) 'BEGIN {
			print "List of files in current directory currently on index"
			print "Index\tName\tDeletion Date"
			i=0
		}
		{
			if ($3 == path) {
				print i "\t" $2 "\t" strftime("%F %T", $4)
			}
			i++
		}
		END {
			if (i == 0) {
				print "No files found."
			}
		}
		' ~/.bin_tmp/metadata
		;;
	"--list-all") echo list-all
		awk -v path=$(readlink -f $PWD) 'BEGIN {
			print "List of files in current directory currently on index"
			print "Index\tName\tDeletion Date\t\tPath"
			i=0
		}
		{
			i++
			print i "\t" $2 "\t" strftime("%F %T", $4) "\t" $3 
		}
		END {
			if (i == 0) {
				print "No files found."
			}
		}' ~/.bin_tmp/metadata
		;;
	"--revert") echo reverting ;;
	"--help") echo -e $USAGE ;;
	*)
		files=$@
		mkdir -p ~/.bin_tmp
		for file in $files
		do
			if [[ ! -f $file ]];
			then
				echo "$file does not exist"
				exit 1
			fi
			if [[ ! -r $file ]];
			then 
				echo "$file cannot be read"
				exit 1
			fi
			if [[ ! -w $file ]];
			then
				echo "$file cannot be deleted."
				exit 1
			fi
			md5=`md5sum $file` 
			tar -cvzf ~/.bin_tmp/$md5
			rm -rf $file
			echo "$md5 `dirname $(readlink -f remi.sh)` `date -u +%s`" >> ~/.bin_tmp/metadata
		done
esac

