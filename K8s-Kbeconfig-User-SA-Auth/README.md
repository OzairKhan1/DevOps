# Kubernetes Kubeconfig & Jenkins Authentication

### The Best Approach is to Use Jenkin Pod inside the Cluster. Then We don't require the tokens at all. It will be handled automatically. 
###  We just need to install kubectl cli to run commands from pipeline within the pod.  

              **For Jenkins Setup go inside the pod and get the login password**  
------------------------------------------------------------------------

## 1. Overview

This project documents how to authenticate **Jenkins or Any External Application**  with a Kubernetes
cluster using a Kubernetes `kubeconfig` file.

The main concepts are: - kubeconfig - clusters - users - contexts -
namespaces - CA certificates - client certificates and private keys -
authentication tokens - Jenkins credentials - Jenkins-to-Kubernetes
authentication - RBAC

The core architecture is:

``` text
Jenkins
   |
   | kubeconfig
   v
Kubernetes API Server
   |
   +-- Authentication
   +-- RBAC Authorization
```

------------------------------------------------------------------------

## 2. Kubeconfig Mental Model

A kubeconfig normally contains three major pieces:

``` text
clusters
users
contexts
```

Remember:

``` text
Cluster = Where am I connecting?
User    = Who am I?
Context = Which user connects to which cluster?
```

A context combines a cluster, a user, and optionally a default
namespace.

``` text
             KUBECONFIG
                  |
       +----------+----------+
       |          |          |
    Cluster     User      Context
       |          |          |
   Where?       Who?      Combines
                           Cluster +
                           User +
                           Namespace
```

------------------------------------------------------------------------

## 3. Cluster

Example:

``` yaml
clusters:
- name: my-cluster
  cluster:
    server: https://10.0.0.10:6443
    certificate-authority-data: <CA_DATA>
```

### `server`

The Kubernetes API server endpoint:

``` yaml
server: https://10.0.0.10:6443
```

### `certificate-authority-data`

The CA certificate is used to establish trust in the Kubernetes API
server.

Think:

``` text
CA -> "I trust/verify the SERVER."
```

------------------------------------------------------------------------

## 4. User

A user contains client authentication information.

### Client certificate authentication

``` yaml
users:
- name: admin
  user:
    client-certificate-data: <CLIENT_CERT>
    client-key-data: <CLIENT_KEY>
```

The client certificate identifies the client and the private key proves
possession of the corresponding key.

### Token authentication

``` yaml
users:
- name: developer
  user:
    token: <TOKEN>
```

The token is another way for the client to authenticate.

Remember:

``` text
Client certificate + key -> authenticate client
Token                    -> authenticate client
```

------------------------------------------------------------------------

## 5. Difference b/w CA vs Client Certificate

This was one of the main points of confusion.

### CA

The CA is normally under `cluster`:

``` yaml
clusters:
- name: my-cluster
  cluster:
    certificate-authority-data: <CA>
```

Its purpose is primarily to verify/trust the Kubernetes API server.

### Client certificate

The client certificate is under `user`:

``` yaml
users:
- name: admin
  user:
    client-certificate-data: <CERT>
    client-key-data: <KEY>
```

Its purpose is to authenticate the client/user.

The easiest memory trick:

``` text
CA
 |
 +--> "I trust the SERVER."

Client Certificate + Key
 |
 +--> "I am the CLIENT."

Token
 |
 +--> "I am the CLIENT."
```

After authentication, Kubernetes RBAC determines what the identity is
allowed to do.

------------------------------------------------------------------------

## 6. Context

Example:

``` yaml
contexts:
- name: developer-development
  context:
    cluster: development
    user: developer
    namespace: dev
```

This means:

``` text
Context: developer-development
Cluster: development
User: developer
Namespace: dev
```

In plain English:

> Use the developer credentials to access the development cluster, with
> `dev` as the default namespace.

------------------------------------------------------------------------

## 7. One User Can Have Multiple Contexts

A context has one default namespace. You cannot define multiple
namespaces in one context.

Instead, the same user can be reused by multiple contexts:

``` yaml
contexts:

- name: developer-dev
  context:
    cluster: development
    user: developer
    namespace: dev

- name: developer-test
  context:
    cluster: development
    user: developer
    namespace: test

- name: developer-prod
  context:
    cluster: development
    user: developer
    namespace: production
```

The relationship is:

``` text
developer
   |
   +-- developer-dev
   +-- developer-test
   +-- developer-prod
```

Alternatively, keep one context and specify the namespace:

``` bash
kubectl get pods -n production
```

------------------------------------------------------------------------

## 8. Important `kubectl config` Commands

### View kubeconfig

``` bash
kubectl config view
```

### View configuration for the current context

``` bash
kubectl config view --minify
```

### List contexts

``` bash
kubectl config get-contexts
```

Example:

``` text
CURRENT   NAME                    CLUSTER       AUTHINFO    NAMESPACE
*         developer-dev           development   developer   dev
          developer-test          development   developer   test
          admin-prod              production    admin       prod
```

The `*` identifies the current context.

### Show current context

``` bash
kubectl config current-context
```

### Switch context

``` bash
kubectl config use-context developer-test
```

### List clusters

``` bash
kubectl config get-clusters
```

### List users

``` bash
kubectl config get-users
```

### Create/update a context

``` bash
kubectl config set-context developer-test   --cluster=development   --user=developer   --namespace=test
```

### Delete a context

``` bash
kubectl config delete-context developer-test
```

### Rename a context

``` bash
kubectl config rename-context old-name new-name
```

------------------------------------------------------------------------

## 9. Test Kubeconfig Manually

Before configuring Jenkins, verify that the kubeconfig works from the
Jenkins VM.

``` bash
kubectl --kubeconfig /path/to/kubeconfig get pods -A
```

If this works, then the kubeconfig and basic network access are working.

This also separates:

``` text
Kubernetes/kubeconfig problem
        vs
Jenkins configuration problem
```

------------------------------------------------------------------------

## 10. Jenkins Credentials

The kubeconfig should not be hardcoded in the Jenkinsfile.

In Jenkins:

``` text
Manage Jenkins
  -> Credentials
  -> Add Credentials
```

Use:

``` text
Kind: Secret file
ID:   kubeconfig
```

The secret file should be the **complete kubeconfig**, not just the
token or CA.

A complete kubeconfig can contain:

``` text
Cluster information
+
Authentication information
+
Contexts
```

Never commit a real kubeconfig containing secrets to GitHub.

------------------------------------------------------------------------

## 11. Jenkins Pipeline

A simple pipeline for testing Kubernetes authentication:

``` groovy
pipeline {
    agent any

    stages {
        stage('Test Kubernetes Authentication') {
            steps {
                withCredentials([
                    file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')
                ]) {
                    sh '''
                        kubectl get pods -A
                    '''
                }
            }
        }
    }
}
```

The important part is:

``` groovy
withCredentials([
    file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')
])
```

Jenkins provides the secret as a temporary file and sets `KUBECONFIG` to
its path.

Therefore, you do not necessarily need:

``` bash
export KUBECONFIG=...
```

inside the shell.

You can also be explicit:

``` bash
kubectl --kubeconfig "$KUBECONFIG" get pods -A
```

------------------------------------------------------------------------

## 12. Complete Authentication Flow

``` text
                 Jenkins
                    |
                    v
          Jenkins Credentials
                    |
              Secret File
                    |
                    v
                kubeconfig
                    |
        +-----------+-----------+
        |           |           |
     Cluster      User       Context
        |           |           |
        +-----------+-----------+
                    |
                    v
           Kubernetes API Server
                    |
                    v
              Authentication
                    |
                    v
                  RBAC
                    |
              +-----+-----+
              |           |
            Allow        Deny
```

------------------------------------------------------------------------

## 13. Security Rules

A kubeconfig can contain sensitive credentials:

``` yaml
token: <SECRET>
```

or:

``` yaml
client-certificate-data: <CERT>
client-key-data: <PRIVATE_KEY>
```

Therefore:

-   Do not commit a real kubeconfig to GitHub.
-   Do not hardcode tokens in the Jenkinsfile.
-   Do not print the kubeconfig in Jenkins logs.
-   Store sensitive kubeconfig data in Jenkins Credentials.
-   Use least-privilege RBAC permissions.

------------------------------------------------------------------------

# Problems and Questions Faced
Question:

> Should I store the token, CA, certificate, and key separately?

Answer:

When using the kubeconfig approach, store the **complete kubeconfig as a
Jenkins Secret File**.

It can contain:

``` text
Cluster
User
Context
CA
Token OR client certificate/private key
```

------------------------------------------------------------------------

## 2. Is the CA the same as the client certificate?

No.

``` text
CA
 -> verifies/trusts the Kubernetes server

Client certificate
 -> identifies/authenticates the client
```

------------------------------------------------------------------------

## 3. Why can one user use a token while another uses a certificate?

They are different client authentication mechanisms.

Token:

``` yaml
user:
  token: <TOKEN>
```

Certificate:

``` yaml
user:
  client-certificate-data: <CERT>
  client-key-data: <KEY>
```

------------------------------------------------------------------------

## 4. Does every user need a separate context?

No.

The same user can be reused in multiple contexts.

``` text
developer
   |
   +-- developer-dev
   +-- developer-test
   +-- developer-prod
```

------------------------------------------------------------------------

## 5. Can one context contain multiple namespaces?

No.

A context has one default namespace.

Use:

``` bash
kubectl get pods -n test
```

or create separate namespace-specific contexts.

------------------------------------------------------------------------

## 6. Do I need to export `KUBECONFIG`?

Not necessarily.

If Jenkins provides:

``` text
KUBECONFIG=/path/to/kubeconfig
```

kubectl can use it automatically.

You can also explicitly specify:

``` bash
kubectl --kubeconfig "$KUBECONFIG" get pods
```

------------------------------------------------------------------------

## 7. Why test from the Jenkins VM first?

Testing directly from the Jenkins VM confirms that:

-   the kubeconfig is valid
-   kubectl can authenticate
-   the Jenkins VM can reach the Kubernetes API server
-   the Kubernetes credentials have access

Then Jenkins configuration can be tested separately.

------------------------------------------------------------------------

# Final Mental Model

The whole kubeconfig can be remembered with one sentence:

> **The cluster tells kubectl where Kubernetes is, the user tells
> kubectl who is connecting, and the context tells kubectl which user
> should connect to which cluster and with which default namespace.**

``` text
                    KUBECONFIG
                         |
          +--------------+--------------+
          |              |              |
       CLUSTER          USER         CONTEXT
          |              |              |
       Where?          Who?          Which
                                      combination?
          |              |              |
   API Server/CA   Token or Cert    Cluster + User
                                      + Namespace
                         |
                         v
                      kubectl
                         |
                         v
                Kubernetes API Server
                         |
                         v
                  Authentication
                         |
                         v
                        RBAC
                         |
                         v
                   Allowed/Denied
```
