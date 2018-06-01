#!/bin/ksh

Dir=/tmp/memusage.$$
Lock=/tmp/memusage.lck
Tmp=$Dir/pmap.out
Total=$Dir/total

mkdir $Dir

if [[ -f $Lock ]]; then
    print -u 2 "Another instance is already running.  Please try again later."
    exit 1
else
    touch $Lock
    trap "rm -rf $Dir $Lock; exit" 2 3 15
    print -u 2 "Collecting memory usage... Please be patient...\n"
fi

if [[ $USER == root ]]; then
    user_list=`ps -eo user | tail -n +2 | sort | uniq`
else
    user_list=$USER
fi
for u in $user_list; do
    User=$Dir/$u

    > $Tmp
    for p in `ps -eo user,pid | awk '$1 ~ /^'$u'$/ { print $2 }'`; do
	pmap $p 2> /dev/null | awk '
BEGIN { FS="[ K]+" }
NR == 1 { s=$0 }
$3 ~ /.w.-./ { i+=$2 }
END { printf("\t%d\t%s\n", i, s) }'
    done >> $Tmp
    awk '{ i+=$1 } END { printf("'$u'\t%dkB\n", i) }' $Tmp >> $Total
    tail -1 $Total > $User
    print "\tkB\tPID\tProcess" >> $User
    sort -nr $Tmp >> $User
done

print "Process Memory (Users w/ 100MB+):"
for u in `sort -nr $Total | cut -f1`; do
    size=`awk '$1 ~ /^'$u'$/ { split($2, a, "kB"); print a[1] }' $Total`
    if (($size > 102400)); then
	echo
	cat $Dir/$u
    fi
done

print "\nShared Memory (kB):"
if [[ $USER == root ]]; then
    user_list=`ipcs -m | awk '$0 !~ /^$/ { print $3 }' | tail -n +3 | sort | uniq`
else
    user_list=$USER
fi
for i in $user_list; do
    print -n "$i\t"
    ipcs -a | awk '$3 ~ /'$i'/ { i+=$5 } END { printf("%d\n", i/1024+0.5) }'
done

rm -rf $Dir $Lock
[root@ny-fnoap-001 bin]# more memusage
#!/bin/ksh

Dir=/tmp/memusage.$$
Lock=/tmp/memusage.lck
Tmp=$Dir/pmap.out
Total=$Dir/total

mkdir $Dir

if [[ -f $Lock ]]; then
    print -u 2 "Another instance is already running.  Please try again later."
    exit 1
else
    touch $Lock
    trap "rm -rf $Dir $Lock; exit" 2 3 15
    print -u 2 "Collecting memory usage... Please be patient...\n"
fi

if [[ $USER == root ]]; then
    user_list=`ps -eo user | tail -n +2 | sort | uniq`
else
    user_list=$USER
fi
for u in $user_list; do
    User=$Dir/$u

    > $Tmp
    for p in `ps -eo user,pid | awk '$1 ~ /^'$u'$/ { print $2 }'`; do
	pmap $p 2> /dev/null | awk '
BEGIN { FS="[ K]+" }
NR == 1 { s=$0 }
$3 ~ /.w.-./ { i+=$2 }
END { printf("\t%d\t%s\n", i, s) }'
    done >> $Tmp
    awk '{ i+=$1 } END { printf("'$u'\t%dkB\n", i) }' $Tmp >> $Total
    tail -1 $Total > $User
    print "\tkB\tPID\tProcess" >> $User
    sort -nr $Tmp >> $User
done

print "Process Memory (Users w/ 100MB+):"
for u in `sort -nr $Total | cut -f1`; do
    size=`awk '$1 ~ /^'$u'$/ { split($2, a, "kB"); print a[1] }' $Total`
    if (($size > 102400)); then
	echo
	cat $Dir/$u
    fi
done

print "\nShared Memory (kB):"
if [[ $USER == root ]]; then
    user_list=`ipcs -m | awk '$0 !~ /^$/ { print $3 }' | tail -n +3 | sort | uniq`
else
    user_list=$USER
fi
for i in $user_list; do
    print -n "$i\t"
    ipcs -a | awk '$3 ~ /'$i'/ { i+=$5 } END { printf("%d\n", i/1024+0.5) }'
done

rm -rf $Dir $Lock
