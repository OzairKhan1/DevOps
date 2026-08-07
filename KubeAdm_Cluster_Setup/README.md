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

**Setup has Completed Here.**
----------------------------------------------------
 
**This  Section is For disabling Iptables on Oracle Cloud**

### Step 1 — Locate what's loading the rules (diagnostic only)
```bash
sudo find / -name "iptables_fromoracle*" 2>/dev/null
cat /etc/network/if-pre-up.d/iptables-load 2>/dev/null
systemctl list-units --type=service | grep -i iptables
systemctl list-unit-files | grep -i netfilter

### Step 2 — Disable the loader so it won't restore rules on boot
```bash
sudo systemctl disable netfilter-persistent
sudo systemctl stop netfilter-persistent

### Step 3 — Flush live rules AND overwrite the saved rules file
### (disabling the service stops it auto-loading, but the saved file
### on disk still has Oracle's REJECT rules until you re-save over it)
```bash
sudo iptables -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo netfilter-persistent save

### Step 4 — Confirm the saved file now reflects the open state
```bash
sudo cat /etc/iptables/rules.v4

### Step 5 — Reboot-test to confirm it holds (do this at a non-critical moment)
```bash
sudo reboot
### after it comes back up:
```bash
sudo iptables -L -n -v



