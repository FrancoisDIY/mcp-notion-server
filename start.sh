#!/bin/sh
# Fonction pour gérer le signal de fermeture
trap "kill \$APP_PID; exit" SIGINT SIGTERM

# Démarre l'application principale en arrière-plan
node build/index.js &
APP_PID=$!

# Lance un petit serveur HTTP en arrière-plan pour les healthchecks
while true; do { echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"; } | nc -l -p 3000 > /dev/null 2>&1; done &
HTTP_PID=$!

# Attend que l'application principale se termine
wait $APP_PID 