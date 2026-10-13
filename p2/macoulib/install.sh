# Va chercher le script d'installation officiel sur le site de K3s. | sh - : Passe (tuyante) ce script directement à l'exécuteur de commandes (Shell) pour qu'il le lance immédiatement.
curl -sfL https://get.k3s.io | sh -

# On télécharge le script d'installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh

# On exécute le script avec les droits administrateur
sudo sh get-docker.sh

#On va donc ajouter ton utilisateur vagrant au groupe officiel de Docker :

sudo usermod -aG docker vagrant 
#cd projet 
 docker compose build

 # etu peux voir pour voir les image docker images 
#et importer dans k3s image . 
docker save projet-app1 projet-app2 projet-app3 | sudo k3s ctr images import -

#Pour vérifier que tes images sont bien arrivées dans le "ventre" de k3s utilise un outil appelé crictl
sudo k3s crictl images

#cree un fichier de deploiement deployment.yaml  metter les instructions a linterieur  et deploier avec ... 

 sudo kubectl apply -f deployment.yaml 

# voir si ca ete bien fait  et reusssi  la commande la plus utiliser est la deuxoieme  Elle te permet de voir tes vrais conteneurs tourner en direct si les pods tourne pas voir dans exmeple car cest elle qui dit le plus la verite si un conteneur tourne 

sudo kubectl get deployments
sudo kubectl get pods


sudo kubectl apply -f service.yaml
# Demande à K3s d'afficher tes Services en mémoire   et  deuxieme C'est la commande magique pour vérifier que le "radar  
# Dans la colonne ENDPOINTS, tu dois voir les adresses IP réelles de tes Pods avec leur port

sudo kubectl get svc

sudo kubectl get endpoints
# pour ingress  et verifier avec la deuxieme commande 


sudo kubectl apply -f ingress.yaml
 sudo kubectl get ingress