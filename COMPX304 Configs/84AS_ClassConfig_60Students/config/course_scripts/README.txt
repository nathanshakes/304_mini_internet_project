Files placed in this directory are made accessible within most containers.

This directory is mounted read-only as /scripts/ in the following containers:
  * hosts
  * routers
  * switches
  * ssh hosts


Scripts from COMPX304:

./shutdown-net and ./start-net

Act as a replacement to restarting the docker container to load network
configuration. Similar to /etc/init.d/networking stop/start but is careful to
avoid removing configuration from the ssh interface.


./flush-route-cache

Flushes the route cache without the need to restart the docker container.
This also flushes cached ICMP redirect messages, so that students can capture
them in the lab.

./start_attack <dest IP>

Attack script that targets the supplied destination IP for the 304 lab.
Targets port 23.

./generate_traffic <dest IP>

Additional unused attack script, targets port 80.

./kill_old_ssh_sessions.sh

Should no longer be needed 8c60cb, should have fixed issues with dropped ssh
sessions. This script will clean up/kill old ssh sessions (1 week or older)
under the assumption that these were not closed correctly.
