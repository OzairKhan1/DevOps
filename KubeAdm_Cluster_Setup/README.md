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

#Setup has Completed Here.
----------------------------------------------------  
----------------------------------------------------
**NOTE**:   Check the calico yaml for these changes
  
kubectl get ippool default-ipv4-ippool -o yaml  

Confirm **vxlanMode**: **Always** and **ipipMode**: **Never** before moving on. If the sed didn't match (manifest changed), patch it directly instead:   

kubectl patch ippool default-ipv4-ippool --type merge -p '{"spec":{"ipipMode":"Never","vxlanMode":"Always"}}'  

----------------------------------------------------
