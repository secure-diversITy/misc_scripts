# misc_scripts

some (hopefully) useful scripts

## manage-deb-repo.sh

due to a heavy re-write this is currently **WIP** and so **not ready for productive use** yet.

It is a tool for syncing debian mirrors to a local folder by APTLY. On top of that this can be used to add your local custom repos as well (once finished).

## ufw-dyndns-updater.sh

updates your UFW firewall with a host having no fixed IP but dynamic DNS

1. create a dnydns name (dozens of free services avail)
1. put that script on your server in a secure place (chmod 700, chown root)
1. replace the variables in the script to match your needs
1. set DEBUG=1 at the top of the script & run a test (should update UFW)
1. still with DEBUG=1 test it directly again (should not update UFW)
1. if all is working as expected: set DEBUG=0 again and add a cron job (see within the script comment)
