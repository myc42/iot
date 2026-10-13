# Inception of Things (IoT)

> Introduction pratique à l'**Infrastructure as Code (IaC)**, à la virtualisation système et à l'orchestration de conteneurs avec **Vagrant** et **K3s**.

---

## 📑 Sommaire

1. [Prérequis & Environnement (Postes 42)](#-prérequis--environnement-postes-42)
2. [Partie 1 : Cluster K3s Multi-Nœuds](#-partie-1--cluster-k3s-multi-nœuds)
   - [Architecture](#architecture-p1)
   - [Points techniques clés](#points-techniques-clés)
   - [Commandes & Validation](#commandes--validation-p1)
3. [Partie 2 : Routage Ingress & Applications Web](#-partie-2--routage-ingress--applications-web)
   - [Architecture & Routage](#architecture--routage-p2)
   - [Commandes & Validation](#commandes--validation-p2)
4. [Dépannage & Astuces Soutenance](#-dépannage--astuces-soutenance)

---

## ⚙️ Prérequis & Environnement (Postes 42)

En raison des quotas de disque restreints sur la session utilisateur (`~` limité), vous devez impérativement rediriger le cache Vagrant et les disques virtuels VirtualBox vers le SSD local (`/goinfre`) avant de lancer les commandes :

```bash
export VAGRANT_HOME="/goinfre/$USER/vagrant_home"
VBoxManage setproperty machinefolder /goinfre/$USER/virtualbox_vms
```

---

## 🚀 Partie 1 : Cluster K3s Multi-Nœuds

Mise en place automatisée d'un mini-cluster Kubernetes composé d'un nœud maître (Control Plane) et d'un nœud worker (Agent).

### Architecture P1

| Machine | Rôle K3s | Hostname | IP Privée | Ressources Allouées |
| :--- | :--- | :--- | :--- | :--- |
| **VM 1** | Server (Control Plane) | `jmafueniS` | `192.168.56.110` | 1 vCPU / 1024 Mo RAM |
| **VM 2** | Agent (Worker) | `jmafueniSW` | `192.168.56.111` | 1 vCPU / 1024 Mo RAM |

### Points techniques clés

* **Échange automatisé du token :** Le `node-token` généré par le Server dans `/var/lib/rancher/k3s/server/node-token` est déposé dans le dossier partagé `/vagrant` pour permettre la jonction du Worker.
* **Symétrie Flannel (CNI) :** Forçage des directives `--flannel-iface eth1` et `--advertise-address` sur les deux nœuds pour garantir que le trafic inter-pods passe par le réseau privé (`192.168.56.0/24`) et non par l'interface NAT (`eth0`).
* **Permissions Kubeconfig :** Option `--write-kubeconfig-mode 644` appliquée pour pouvoir exécuter `kubectl` avec l'utilisateur `vagrant` sans préfixe `sudo`.

### Commandes & Validation P1

```bash
cd p1
vagrant up
```

#### 1. Vérification du statut des nœuds
```bash
vagrant ssh jmafueniS -c "kubectl get nodes -o wide"
```
*Résultat attendu :* Les 2 machines affichent le statut **Ready** avec leurs adresses IP respectives.

#### 2. Test de connectivité réseau inter-pods (Flannel)
```bash
vagrant ssh jmafueniS
kubectl create deployment net-test --image=nginx --replicas=2
kubectl get pods -o wide

# Envoyer une requête HTTP depuis le pod du serveur vers le pod du worker
kubectl exec <POD_SUR_SERVEUR> -- curl -s -I http://<IP_POD_SUR_WORKER>
# Résultat attendu : HTTP/1.1 200 OK

# Nettoyage du test
kubectl delete deployment net-test
exit
```

#### 3. Nettoyage complet
```bash
vagrant destroy -f
rm -f token
```

---

## 🌐 Partie 2 : Routage Ingress & Applications Web

Déploiement sur un nœud unique de 3 applications web avec routage HTTP géré par **Traefik** (Ingress Controller K3s).

### Architecture & Routage P2

* **VM unique :** `jmafueniS` (`192.168.56.110`)
* **Déploiement continu :** Dépôt des manifests YAML dans `/var/lib/rancher/k3s/server/manifests/` pour une synchronisation automatique par K3s.

| Application | Réplicas | Règle Ingress / Host | Comportement attendu |
| :--- | :---: | :--- | :--- |
| **`app1`** | `1` | `Host: app1.com` | Affiche l'Application 1 |
| **`app2`** | `3` | `Host: app2.com` | Affiche l'Application 2 (répartie sur 3 pods) |
| **`app3`** | `1` | Route par défaut (catch-all) | Répond pour toute requête directe par IP ou nom d'hôte non assigné |

### Commandes & Validation P2

```bash
cd p2
vagrant up
```

Une fois le provisionnement terminé, exécutez les requêtes de test depuis votre terminal hôte :

```bash
# 1. Test du routage vers app1
curl -H "Host: app1.com" http://192.168.56.110
# Attendu : Hello from Application 1!

# 2. Test du routage vers app2
curl -H "Host: app2.com" http://192.168.56.110
# Attendu : Hello from Application 2!

# 3. Test du fallback par défaut (app3)
curl http://192.168.56.110
curl -H "Host: domaine-inconnu.com" http://192.168.56.110
# Attendu : Hello from Application 3!

# 4. Contrôle des pods et des 3 réplicas d'app2
vagrant ssh -c "kubectl get pods -o wide"

# 5. Nettoyage
vagrant destroy -f
```

---

## 🛠️ Dépannage & Astuces Soutenance

* **Mise à jour d'un ConfigMap sans effet :**  
  Modifier un ConfigMap ne redémarre pas automatiquement les conteneurs Nginx en mémoire. Pour forcer l'actualisation sans recréer la VM :
  ```bash
  kubectl rollout restart deployment app1 app2 app3
  ```
* **Erreur `curl: (7) Failed to connect ... port 80` :**  
  Traefik prend 15 à 30 secondes pour démarrer et lier le port 80. Dans `scripts/setup.sh`, assurez-vous d'utiliser l'attente active :
  ```bash
  kubectl rollout status deployment/traefik -n kube-system --timeout=90s
  ```
* **Libération des ressources :**  
  Détruisez systématiquement les VMs terminées avec `vagrant destroy -f` pour éviter de bloquer la mémoire vive et saturer `/goinfre`.