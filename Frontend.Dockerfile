FROM ubuntu/nginx:1.18-20.04_beta as base

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update \
    && apt-get -y upgrade

# install curl
RUN apt-get update \
    && apt-get -y install curl

# install nodejs via nvm
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm

ENV NODE_VERSION 20.17.0

RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.1/install.sh | bash

RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NDOE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# install vim and git
RUN apt-get update
RUN apt-get -y install vim 
RUN apt-get -y install git

FROM base as setup-and-install-packages

# copy files to container
WORKDIR /var/www/html

ARG PROJECT_PATH=.
ENV PROJECT_PATH=${PROJECT_PATH}

COPY ${PROJECT_PATH}/package.json ./
COPY ${PROJECT_PATH}/package-lock.json ./

RUN npm install

COPY ${PROJECT_PATH} .

RUN git config --global --add safe.directory /var/www/html

EXPOSE 80

# dev build 
FROM setup-and-install-packages as dev-build
# RUN npm run generate -- -o
RUN npm run build --port=8001

# dev server
FROM dev-build as dev
COPY --from=dev-build /var/www/hmtl/dist /usr/share/nginx/html
COPY nginx-frontend.conf /etc/nginx/nginx.conf

# prod build
FROM setup-and-install-packages as prod-build
RUN npm run build -- --mode production

# prod server
FROM prod-build as prod
COPY --from=prod-build /var/www/html/dist /usr/share/nginx/html
COPY nginx-frontend.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]