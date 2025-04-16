# Étape de build
FROM node:18-alpine AS builder

# Crée un utilisateur dédié pour la sécurité
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copie d'abord tous les fichiers nécessaires pour le build
COPY package*.json ./
COPY tsconfig.json ./
COPY src ./src

# Désactive le script prepare pour éviter l'exécution en boucle de build
RUN npm set-script prepare ""

# Installe toutes les dépendances (y compris dev pour pouvoir builder)
RUN npm install

# Build l'application
RUN npm run build

# Étape finale avec une image légère
FROM node:18-alpine

WORKDIR /app

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

# Lance l'application
CMD ["node", "build/index.js"]
