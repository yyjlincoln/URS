# ---- Build stage ----
FROM node:16-bullseye-slim AS build
RUN apt-get update && apt-get install -y openssl libssl-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY prisma/ ./prisma/
COPY src/ ./src/
COPY webpack.config.js tsconfig.json ./
# Webpack shell plugin calls scripts/ during build.
# Provide no-op stubs so build succeeds without a live database.
RUN mkdir -p scripts && \
    echo '#!/bin/sh' > scripts/prisma-gen.sh && \
    echo '#!/bin/sh' > scripts/prisma-migrate.sh && \
    echo '#!/bin/sh' > scripts/launch-dev.sh
RUN yarn prisma generate
RUN yarn build

# ---- Production stage ----
FROM node:16-bullseye-slim
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production
COPY prisma/ ./prisma/
RUN npx prisma generate
COPY --from=build /app/dist/ ./dist/

EXPOSE 3030

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "const http=require('http');http.get('http://localhost:3030/',r=>{process.exit(r.statusCode<400?0:1)}).on('error',()=>process.exit(1))"

CMD ["node", "dist/server.js"]
