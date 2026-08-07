Step 1

Run common.sh on ALL machines

Master
-------
./common.sh

Worker1
--------
./common.sh

Worker2
--------
./common.sh

----------------------------------------------------

Step 2

On Master

./master.sh

----------------------------------------------------

Step 3

Copy the generated kubeadm join command.

----------------------------------------------------

Step 4

Run worker.sh

Paste the join command.

----------------------------------------------------

Step 5

Verify

kubectl get nodes


Setup has Completed Here. The Below Section is For disabling Iptables on Oracle Cloud 

----------------------------------------------------

These Are Some Extra-Tools 

```bash
sudo find / -name "iptables_fromoracle*" 2>/dev/null
cat /etc/network/if-pre-up.d/iptables-load 2>/dev/null
systemctl list-units --type=service | grep -i iptables
systemctl list-unit-files | grep -i netfilter


Step 2 — Since you already flushed and want AWS-EC2-like behavior (no host firewall interfering), just disable the loader

sudo systemctl disable netfilter-persistent
sudo systemctl stop netfilter-persistent

This stops it from restoring any saved rules on boot — but be careful, since you saved rules earlier with netfilter-persistent save,
 that save file now needs to be cleared too so a future manual netfilter-persistent reload doesn't bring the block back:

sudo iptables -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo netfilter-persistent save

Step 3 — Confirm the actual rules file content is now empty/open
bash
sudo cat /etc/iptables/rules.v4

Step 4 — Reboot-test to be sure (do this on a non-critical moment)

sudo reboot





