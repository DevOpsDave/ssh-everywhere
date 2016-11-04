#!/usr/bin/env python

import argparse
import sys
import subprocess
import paramiko
from os.path import expanduser


class GlobalExceptions(Exception):
    pass


class AWScli(object):

    def __init__(self):
        self.binary = 'aws'

    def execute(self, command_str):
        execute_cmd = command_str.split()
        try:
            output = subprocess.check_output(execute_cmd).rstrip('\n')
        except OSError:
            raise GlobalExceptions('{0} is not a valid executable'
                                   .format(execute_cmd[0]))
        return output


class DiscoverHosts(object):

    def __init__(self, region):
        self.region = region
        self.aws_obj = AWScli()
        self.hosts = []

    def get_by_group_name(self, group_name):
        cstr = "aws ec2 describe-instances "
        cstr += "--region {0} ".format(self.region)
        cstr += "--filter Name=group-name,Values={0} ".format(group_name)
        cstr += "--query Reservations[*].Instances[*].[Tags[?Key==`Name`]] "
        cstr += "--output text"
        hosts = self.aws_obj.execute(cstr)
        output = []
        for host in hosts.split('\n'):
            output.append(host.split('\t')[1].rstrip('\n'))
        return output


class SshCtrl(object):

    def __init__(self, hosts):
        self.hosts = hosts
        self.ssh_config_file = expanduser('~') + '/.ssh/config'
        self.ssh_obj = paramiko()
        self.bastion = self.get_bastion()

    def get_bastion(self):
        ssh_config_fp = open(self.ssh_config_file)
        ssh_config = self.ssh_obj.config.SSHConfig()
        ssh_config.parse(ssh_config_fp)
        config = ssh_config.lookup(self.hosts[0])
        return config['proxycommand'].split()[1]

    def connect(self):
        


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--session-name',
                        required=False,
                        help='Name of session.')
    parser.add_argument('-h', '--host-list',
                        required=False,
                        help='list of hosts.')
    parser.add_argument('--sec-group', help='Name of security group.')
    parser.add_argument('--region', default='us-east-1')
    args = parser.parse_args()

    # Get the host list.
    hosts = []
    dh_obj = DiscoverHosts(args.region)
    if args.host_list:
        hosts = dh_obj.get_host_list(args.host_list)
    elif args.sec_group:
        hosts = dh_obj.get_by_group_name(args.sec_group)
    else:
        print "No hosts given."
        sys.exit(1)

    # Got the host list.  Now login.  We want to make sure we login to bastion
    # 1 time.
