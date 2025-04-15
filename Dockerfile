# Étape de build
FROM node:18-alpine AS builder

# Crée un utilisateur dédié pour la sécurité
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copie seulement les fichiers nécessaires pour installer les dépendances
COPY package*.json ./

# Installe les dépendances sans déclencher de scripts inutiles
RUN npm install --ignore-scripts

# Copie les sources et le tsconfig
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript selon ton tsconfig
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

# Indique que cette variable doit être fournie via Coolify (ne jamais mettre directement ici)
ENV NOTION_API_TOKEN=${NOTION_API_KEY}

# Lance l'application
CMD ["node", "build/index.js"]
