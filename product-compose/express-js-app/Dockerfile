# following dockerfile initializes an alpine instance with the node js runtime and the express server
FROM node:alpine as base

WORKDIR /app


COPY . .

CMD ["node", "./app.js"]