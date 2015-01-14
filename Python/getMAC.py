#!/usr/bin/env python
import re, uuid
print ':'.join(re.findall('..', '%012x' % uuid.getnode()))
