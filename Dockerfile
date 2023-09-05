# base image
# FROM node:10.15.0
FROM node:20

RUN mkdir /app
# install and cache app dependencies
WORKDIR /app
COPY package*.json ./
RUN npm install
# RUN npm install vue vite vuetify
# RUN npm install -g vue vite vuetify

# WORKDIR /usr/src/app
# RUN apt-get update && apt-get install -y gcc make python3 python3-pip\
    # && pip3 install --no-cache-dir sqlite-web

# ENV PATH /usr/local/lib/python3.7/site-packages:$PATH

# CMD npm run env -- vitepress dev --host 0.0.0.0 --port 4173

COPY ./start-dev.sh /
RUN chmod +x /start-dev.sh
CMD ["/bin/bash", "-c", "source /start-dev.sh"]