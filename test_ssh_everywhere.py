#!/usr/bin/env python

from ssh_everywhere import GlobalExceptions
from ssh_everywhere import AWScli
from ssh_everywhere import DiscoverHosts

import unittest


class TestAWScli(unittest.TestCase):

    def test_execute(self):
        aws_obj = AWScli()
        output = aws_obj.execute('echo hi')
        self.assertEqual('hi', output)

    def test_execute_fail_no_binary(self):
        aws_obj = AWScli()
        with self.assertRaises(GlobalExceptions):
            aws_obj.execute('blah')


class TestDiscoverHosts(unittest.TestCase):

    def test_get_by_group_name(self):
        dh_obj = DiscoverHosts('us-east-1')
        output = dh_obj.get_by_group_name('siterr-api-stg')
        expected = [
            'siterr-api-use1b-01.deskstaging.com',
            'siterr-api-use1e-01.deskstaging.com',
            'siterr-wrk-use1e-01.deskstaging.com',
            'siterr-wrk-use1b-01.deskstaging.com'
            ]
        self.assertListEqual(expected, output)


if __name__ == '__main__':
    unittest.main()
