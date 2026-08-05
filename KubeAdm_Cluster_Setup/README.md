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
