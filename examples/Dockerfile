# Quiet Hacker - Dockerfile Preview
FROM node:22-alpine AS base
WORKDIR /app
ENV NODE_ENV=production

# Dependencies
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && \
    npm cache clean --force

# Build
FROM base AS build
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && \
    rm -rf node_modules/.cache

# Production
FROM base AS production
LABEL maintainer="manuartero"
LABEL description="Quiet Hacker API"

RUN addgroup -g 1001 -S app && \
    adduser -S -u 1001 -G app app

COPY --from=deps --chown=app:app /app/node_modules ./node_modules
COPY --from=build --chown=app:app /app/dist ./dist
COPY --from=build --chown=app:app /app/package.json ./

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["node"]
CMD ["dist/server.js"]
