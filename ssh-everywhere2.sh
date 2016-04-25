#!/bin/bash
# ssh-everywhere.sh

# a script to ssh multiple servers over multiple tmux panes 

usage() {
    echo
    echo
    echo "Application Call: "
    echo
    echo "$BNAME sessionname"
    echo "before calling the script do: export HOSTS='host1 host2 host3'"
    echo "as a list of hosts to work on, or you will be promted to type"
    echo "the list in." 
}

starttmux() {
    echo 
    echo $HOSTS
    if [ -z "$HOSTS" ]; then
       echo -n "Please provide of list of hosts separated by spaces [ENTER]: "
       read HOSTS
    fi
    
    tmux new-session -d -s $sessionname 
    for i in $HOSTS
    do
    echo "Adding $i."
    tmux split-window -v -t $sessionname "ssh -l $my_user $i"
    tmux select-layout tiled
    done
    tmux set-window-option synchronize-panes on
    tmux kill-pane -t 0
    tmux attach -t $sessionname 
}

BNAME=`basename $0`
if  [ $# -lt 1 ]; then
    usage
    exit 0
fi

file="$1"
sessionname=`basename $1`
HOSTS=`cat $file`

# my_user
my_user="$2"
if [ "${my_user}N" == "N" ] ; then 
  my_user="$USER"
fi

starttmux
