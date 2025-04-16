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

# Installer curl pour le healthcheck
RUN apk --no-cache add curl

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

# Ajouter un healthcheck simple
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Lance l'application
CMD ["node", "build/index.js"]
