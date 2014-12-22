import syslog

syslog.openlog("test.py")
for i in range(0, 100000):
    syslog.syslog("The process is test.py: %d" % i)
