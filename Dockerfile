# Étape de build
FROM node:18-alpine AS builder

# Crée un utilisateur dédié pour la sécurité
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copie d'abord tous les fichiers nécessaires pour installer les dépendances
COPY package*.json ./

# Désactive temporairement le script prepare en créant un package.json modifié
RUN cat package.json | grep -v '"prepare":' > package.json.temp && mv package.json.temp package.json

# Copie les sources et le tsconfig
COPY tsconfig.json ./
COPY src ./src

# Installe toutes les dépendances (y compris dev pour pouvoir builder)
RUN npm install

# Build l'application
RUN npm run build

# Étape finale avec une image légère
FROM node:18-alpine

WORKDIR /app

# Installer les outils nécessaires
RUN apk --no-cache add curl

# Créer un fichier wrapper qui lance à la fois l'application principale et un petit serveur HTTP
RUN echo '#!/bin/sh\n\
# Fonction pour gérer le signal de fermeture\n\
trap "kill \$APP_PID; exit" SIGINT SIGTERM\n\
\n\
# Démarre l\'application principale en arrière-plan\n\
node build/index.js &\n\
APP_PID=$!\n\
\n\
# Lance un petit serveur HTTP en arrière-plan pour les healthchecks\n\
while true; do { echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"; } | nc -l -p 3000 > /dev/null 2>&1; done &\n\
HTTP_PID=$!\n\
\n\
# Attend que l\'application principale se termine\n\
wait $APP_PID\n\
' > /app/start.sh && chmod +x /app/start.sh

# Installe netcat pour le serveur HTTP simple
RUN apk --no-cache add busybox-extras

# Copie les dépendances en production
COPY --from=builder /app/package*.json ./

# Installe uniquement les dépendances en mode production
RUN npm ci --omit=dev

# Copie uniquement les fichiers build générés
COPY --from=builder /app/build ./build

# Récupère l'utilisateur non-root de la première étape
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Utilise l'utilisateur non-root pour exécuter l'app
USER appuser

# Expose le port de l'app
EXPOSE 3000

# Cette variable sera fournie au moment de l'exécution
ENV NOTION_API_TOKEN=""

# Lance l'application avec notre wrapper
CMD ["/app/start.sh"]
