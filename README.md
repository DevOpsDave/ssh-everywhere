# ssh-everywhere
Integrates ssh and tmux with aws cli to create tmux sessions that open a pane for each aws instance.

Usage:
```bash
Usage: ssh-everywhere
    -s, --session [STRING]           session name
    -l, --host_list [STRING]         path to host list.
    -u, --user [USER]                The user to login as. Default=<current user>
    -m, --max_panes [INT]            Max number of panes per session.
    -r, --aws_region [REGION]        The region to use when looking up hosts.
    -t, --aws_tag [TAG]              The name of the aws tag to use for looking up hosts.
    -d, --debug                      Will print debug info.
        --list-hosts                 Outputs list of hosts and then exits.
        --get-tags                   Output the tags.
```


--get-tags:
For use with --aws-tag.  Prints out pretty json of all hosts and tags.  Use jq
to make sense of it.  Example:
```
./ssh-everywhere.rb -t blah-host* --get-tags | jq '.[] | .name'
"blah-host-01"
"blah-host-02"
