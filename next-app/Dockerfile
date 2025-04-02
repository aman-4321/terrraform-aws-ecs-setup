FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json  ./

RUN npm install

COPY . .

RUN npm run build

FROM node:20-alpine AS production

WORKDIR /app

COPY --from=builder /app/.next/standalone ./.next/standalone
COPY --from=builder /app/public ./.next/standalone/public
COPY --from=builder /app/.next/static ./.next/standalone/.next/static

EXPOSE 80

ENV PORT=80

CMD [ "node", ".next/standalone/server.js" ]
