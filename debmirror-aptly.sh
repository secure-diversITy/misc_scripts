#!/bin/bash
###############################################################################################
#
# Sync, Snapshot, Publish, Cleanup all defined mirrors
#
# Author/Copyright: 2021-2022 "Thomas Fischer <mail |AT| sedi #DOT# one>"
###############################################################################################
VERSION="v1.1"

# format: distribution-codename:component,component distribution-codename:all
# ubuntu-specific: <codename>"-security" allows only "all"
# example: focal:main,universe,multiverse focal-security:all
#SYNCTARGETS="focal:all focal-security:all jammy:all jammy-security:all"

# path where the packages should be stored
DATAPATH=/opt/data/mirror

# specific temporary dir, use when /tmp does not have enough free space
export TMPDIR=$DATAPATH/tmp

# log file
LOG=$DATAPATH/mirror.log

# max retries before a sync will abort
MAXRET=999

# when set to "yes" a graph of the merge + publish results will be created
# and stored in $DATAPATH/<codename>_graph.png
# requires the package: "graphviz"
APTGRAPH=yes

# dry run without changing anything, will just print what would be done
# unset or outcomment for normal usage
DRYRUN=echo

# debug output
DEBUG=1

###############################################################################

# help/usage info
F_HELP(){
    cat << EOH

    Sync, Snapshot, Publish, Cleanup all defined mirrors
    
    Usage:

    $0 -d "distribution-codename:component,component"

    you can specify more then one -d parameter and repeat it up to 4 times.
    the argument for -d HAS TO be quoted when you want do specify multiple combinations for a distribution.

    IMPORTANT:
    !! do not mix distributions within one -d argument !!

    -> e.g. the following is NOT allowed: -d "focal:all jammy:all"
    -> instead use "-d focal:all -d jammy:all"

    Full example:

    $0 -d "focal:main,universe,multiverse focal-security:all" -d "jammy:all jammy-security:all"

EOH
}

# sync process
F_SYNC(){
    [ "$DEBUG" -eq 1 ] && echo "$FUNCNAME started with $1"
    unset target T C
    for target in $1; do
        # extract codename
        T="${target/:*/}"
        # extract components
        C=$(echo "${target/*:/}" | tr , ' ' |grep -v all)

        # sync
        $DRYRUN aptly mirror update -max-tries=$MAXRET $T $C >> $LOG 2>&1

        # create snapshot
        $DRYRUN aptly snapshot create ${T}-snapshot-$(date +%Y%m%d) from mirror $T >> $LOG 2>&1
    done
}

# merge process
F_MERGE(){
    unset target T TS tp
    ARG="$1"
    # extract codename
    T="${ARG/:*/}"
    for target in $ARG; do
        if [ -z "$TS" ];then
            TS="${target/:*/}-snapshot-$(date +%Y%m%d)"
        else
            TS="$TS ${target/:*/}-snapshot-$(date +%Y%m%d)"
        fi
    done
    $DRYRUN aptly snapshot merge -latest ${T}-latest-$(date +%Y%m%d) $TS >> $LOG 2>&1
}

# publish process
F_PUBLISH(){
    ARG="$1"
    # extract codename
    T="${ARG/:*/}"
    if [ -f "$DATAPATH/${T}.init" ];then
        $DRYRUN aptly publish switch $T ${T}-latest-$(date +%Y%m%d) >> $LOG 2>&1 && touch $DATAPATH/${T}.init
    else
        $DRYRUN aptly publish snapshot -distribution=$T ${T}-latest-$(date +%Y%m%d) >> $LOG 2>&1
    fi
    [ "$APTGRAPH" == "yes" ] && $DRYRUN aptly graph -output $DATAPATH/${T}_graph.png >> $LOG 2>&1
}

# cleanup process
F_CLEAN(){
    ARG="$1"
    # extract codename
    T="${ARG/:*/}"
    $DRYRUN aptly snapshot drop ${T}-latest-$(date +%Y%m%d --date="yesterday") >> $LOG 2>&1
    $DRYRUN aptly snapshot drop ${T}-snapshot-$(date +%Y%m%d --date="yesterday") >> $LOG 2>&1
}

# parse parameters
unset SYNCTARGET1 SYNCTARGET2 SYNCTARGET3 SYNCTARGET4
while [ ! -z "$1" ];do
    case $1 in
        -d)
            if [ -z "$SYNCTARGET1" ];then
                SYNCTARGET1="$2"
            elif [ -z "$SYNCTARGET2" ];then
                SYNCTARGET2="$2"
            elif [ -z "$SYNCTARGET3" ];then
                SYNCTARGET3="$2"
            elif [ -z "$SYNCTARGET4" ];then
                SYNCTARGET4="$2"
            else
                echo "Max allowed targets reached (4)"
                F_HELP
                exit 4
            fi
            shift 2
        ;;
        *)
            F_HELP; exit
        ;;
    esac
done

[ -z "$SYNCTARGET1" ] && echo "ERROR: missing target" && F_HELP && exit 4

# execute
for p in $SYNCTARGET1 $SYNCTARGET2 $SYNCTARGET3 $SYNCTARGET4;do
    F_SYNC "$p" && F_MERGE "$p" && F_PUBLISH "$p" && F_CLEAN "$p"
    ERR=$?; [ $ERR -ne 0 ] && echo "ERROR: error >$ERR< occured!" && exit 3
done

[ "$DEBUG" -eq 1 ] && echo end
