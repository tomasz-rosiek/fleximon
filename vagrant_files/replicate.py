#!/usr/bin/env python

"""
replicate py
Small python script to create dummy alerts for sensu
Alerts are created one per file, with a random name, team, and exit code
template.json contains the boilerplate config, which is substituted with
random config for as many alerts as is specified
Sensu services should be restarted after unning this script

USE ONLY FOR TESTING PURPOSE - DO NOT RUN IN PRODUCTION UNLESS YOU KNOW WHAT
YOU ARE DOING
"""

import os
import random
import re
import string

# Read template config
REAL_PATH = os.path.dirname(os.path.realpath(__file__))
FILE_HANDLE = open(REAL_PATH + '/template.json', 'r')
FILE_STRING = FILE_HANDLE.read()
FILE_HANDLE.close()

NUM_OF_CHARS = 5  # number of characters to use for alert name
NUM_OF_FILES = 100  # number of alerts (and files) to create
DIR_NAME = '/etc/sensu/conf.d/'  # where to place config


# run once for each file/alert
for _ in range(NUM_OF_FILES):

    RANDOM_STRING = 'test-' + ''.join(random.choice(string.ascii_lowercase) \
      for _ in range(NUM_OF_CHARS))
    RANDOM_TEAM = random.choice(['webops', 'platops', 'other'])
    RANDOM_EXIT_CODE = random.choice([0, 1, 2, 3])

    # items to substitute from template
    rep = {"random_string": RANDOM_STRING,
           "random_exit_code": str(RANDOM_EXIT_CODE),
           "random_team": RANDOM_TEAM}


    # use these three lines to do the replacement
    rep = dict((re.escape(k), v) for k, v in rep.iteritems())
    pattern = re.compile("|".join(rep.keys()))
    text = pattern.sub(lambda m: rep[re.escape(m.group(0))], FILE_STRING)

    # write file, using random alert name as the file name
    FILE_NAME = DIR_NAME + RANDOM_STRING + '.json'
    FILE_HANDLE = open(FILE_NAME, 'w')
    FILE_HANDLE.write(text)
    FILE_HANDLE.close()
