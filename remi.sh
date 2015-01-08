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
\t--revert index - bring back file with given index to current directory. Invalidates other indexes.\n
"

if [[ $# -lt 1 ]]
then
	echo -e $USAGE
	exit 1
fi

metadir="$HOME/.bin_tmp/"
metafile="$metadir""metadata"

function garbage_collector {
	if [[ -w $metafile ]];
	then
		nfile=$(awk 'NF {
		if ($4 > (systime() - 48*60*60)) {
				print
			} else {
				system("rm '"$metadir"'"$1)
			}
		}' $metafile)
		printf "$nfile" > $metafile
	fi
}

OPTION=$1

case $OPTION in
	"--list")
		garbage_collector
		awk -v path=$(readlink -f $PWD) 'BEGIN {
			print "List of files in current directory currently on index"
			print "Index\tName\tDeletion Date"
			i=0
		}
		NF {
			i++
			if ($3 == path) {
				print i "\t" $2 "\t" strftime("%F %T", $4)
			}
		}
		END {
			if (i == 0) {
				print "No files found."
			}
		}
		' $metafile
		;;
	"--list-all") echo list-all
		garbage_collector
		awk -v path=$(readlink -f $PWD) 'BEGIN {
			print "List of files in current directory currently on index"
			print "Index\tName\tDeletion Date\t\tPath"
			i=0
		}
		NF {
			i++
			print i "\t" $2 "\t" strftime("%F %T", $4) "\t" $3
		}
		END {
			if (i == 0) {
				print "No files found."
			}
		}' $metafile
		;;
	"--revert") 
		if [[ $# -ne 2 ]];
		then
			echo -e $USAGE
		fi
		nol=`wc -l < $metafile`
		index=$2
		if [[ (! -w $metafile) || (($nol -lt $index)) ]];
		then
			echo "File index does not match"
			exit 1
		fi
		filedata=(`sed "$index"'q;d' $metafile`)
		tar -xvzf $metadir${filedata[0]}
		rm $metadir${filedata[0]}
		new_file=`awk 'NR!~'"${index}" $metafile`
		echo "$new_file" > $metafile
		garbage_collector
	;;
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
			echo "$md5 `dirname $(readlink -f remi.sh)` `date -u +%s`" >> $metafile
		done
esac

