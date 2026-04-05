# ---- Build stage ----
FROM node:16-alpine AS build
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
FROM node:16-alpine
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production
COPY prisma/ ./prisma/
RUN npx prisma generate
COPY --from=build /app/dist/ ./dist/

EXPOSE 3030

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3030/ || exit 1

CMD ["node", "dist/server.js"]
