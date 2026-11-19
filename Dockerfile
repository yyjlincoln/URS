# ---- Build stage ----
FROM node:22-trixie-slim AS build
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
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
FROM node:22-trixie-slim
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production && yarn cache clean
# The Prisma CLI is a dev dependency; reuse the client generated in the build stage.
COPY --from=build /app/node_modules/.prisma/ ./node_modules/.prisma/
COPY --from=build /app/dist/ ./dist/

USER node
EXPOSE 3030

CMD ["node", "dist/server.js"]
