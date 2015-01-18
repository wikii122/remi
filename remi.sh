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

function timeout_counter {
	if [[ -w $metafile ]];
	then
		nfile=$(awk 'NF {
		if ($4 > (systime() - 48*60*60)) {
				print
			} else {
                if ($1 != "n") {
				    system("i=$(cat '$metadir'"$1".ref 2>/dev/null);i=$((i-1));echo $i > '$metadir'"$1".ref;")
                }
			}
		}' $metafile) 
		printf "$nfile" > $metafile
	fi
}

function garbage_collector {
	for x in `ls ${metadir}*.ref` 
	do
		if [ ! $x == $metadir".ref" ];
		then
			i=`cat $x`
			if [[ $i -le 0 ]];
			then
				rm -f $x
				rm -f ${x:0:-4}
			fi
		fi
	done
}

OPTION=$1

case $OPTION in
	"--list")
		if [[ ! -f $metafile ]];
		then
			echo "No data on index"
			exit 1
		fi
		timeout_counter
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
		garbage_collector
		;;
	"--list-all") echo list-all
		if [[ ! -f $metafile ]];
		then
			echo "No data on index"
			exit 1
		fi
		timeout_counter
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
		garbage_collector
		;;
	"--revert")
		if [[ ! -f $metafile ]];
		then
			echo "No data on index"
			exit 1
		fi
		if [[ $# -ne 2 ]];
		then
			echo -e $USAGE
		fi
		nol=`wc -l < $metafile`
		index=$2
        if [[ (! -w $metafile) || (($nol -lt $index)) || (( $index -le 0 )) ]];
		then
			echo "File index does not match"
			exit 1
		fi
		filedata=(`awk "NR==$index" $metafile`)
		tar -xvzf $metadir${filedata[0]} --transform "s!^[^/]\+\($\|/\)!${filedata[1]}\1!"
		new_file=`awk 'NR!~'"${index}" $metafile`"\n"
		echo "$new_file" > $metafile
		i=$(cat ~/.bin_tmp/${filedata[0]}.ref)
		i=$((i-1))
		echo "$i" > ~/.bin_tmp/${filedata[0]}.ref
		timeout_counter
		garbage_collector
		;;
	"--help") echo -e $USAGE ;;
	*)
		files=$@
		mkdir -p ~/.bin_tmp
		for file in $files
		do
			if [[ ! -e $file ]];
			then
				echo "$file does not exist"
				exit 1
			fi
			if [[ -d $file ]];
			then
				files="$files `find $file`"
			fi
		done
		for file in $files
		do
			if [[ -d $file ]];
			then 
				continue
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
			if [[ -f ~/.bin_tmp/${md5:0:32}.ref ]];
			then
				i=$(cat ~/.bin_tmp/${md5:0:32}.ref)
				i=$((i+1))
				echo "$i" > ~/.bin_tmp/${md5:0:32}.ref
			else
				echo "1" > ~/.bin_tmp/${md5:0:32}.ref
			fi
			echo "$md5 `dirname $(readlink -f remi.sh)` `date -u +%s`\n" >> $metafile
			garbage_collector
		done
		for file in $files
		do
			rm -rf $file
		done
esac

