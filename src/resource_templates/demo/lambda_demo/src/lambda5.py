#!/usr/bin/python

import sys
import json
import time

body = sys.argv[1]

body = "Hello new Python!"

print('This is intended to be a log message', file=sys.stderr)
print('This is intended to be another log message', file=sys.stderr)

# raise NameError('This is an error')

response = {
        "statusCode": 201,
        "headers": { "Content-Type": "application/json"},
        "body": json.dumps(body)
    }

print(json.dumps(response))