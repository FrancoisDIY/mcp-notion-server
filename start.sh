#!/bin/sh

# Crée un fichier fifo pour la communication
mkfifo /tmp/mcp_pipe
(while true; do
  # Envoie un ping toutes les 10 secondes pour maintenir l'application active
  sleep 10
  echo '{"ping": true}' > /tmp/mcp_pipe
done) &
PING_PID=$!

# Lance un petit serveur HTTP en arrière-plan pour les healthchecks
(while true; do 
  { echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"; } | nc -l -p 3000 > /dev/null 2>&1 
done) &
HTTP_PID=$!

# Démarre l'application principale avec l'entrée du pipe
cat /tmp/mcp_pipe | node build/index.js &
APP_PID=$!

# Fonction pour nettoyer à la sortie
cleanup() {
  echo "Shutting down..."
  kill $PING_PID
  kill $HTTP_PID
  kill $APP_PID
  rm -f /tmp/mcp_pipe
  exit 0
}

# Gestion du signal de fermeture
trap cleanup SIGINT SIGTERM

# Attend que l'application principale se termine
wait $APP_PID
cleanup 