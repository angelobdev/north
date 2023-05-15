FROM node:lts-alpine

WORKDIR /usr/src/app

COPY . .

RUN yarn install

ENTRYPOINT [ "yarn", "start" ]