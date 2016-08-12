FROM bitnami/express:4.13.4-r4

MAINTAINER Bitnami <containers@bitnami.com>

#
# Eclipse Che
#
USER root

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN bitnami-pkg install java-1.8.0_91-0 --checksum 64cf20b77dc7cce3a28e9fe1daa149785c9c8c13ad1249071bc778fa40ae8773
ENV PATH=/opt/bitnami/java/bin:$PATH

#
# Express
#
LABEL che:server:3000:ref=nodejs che:server:3000:protocol=http

#
# MongoDB
#

# From bitnami-docker-mongodb/Dockerfile
ENV BITNAMI_APP_NAME=mongodb \
    BITNAMI_APP_USER=mongo

RUN bitnami-pkg unpack mongodb-3.2.7-1 --checksum 98d972ec5f6a34b3fc7a82e76600d9ac6c209537d93402e3b29de9e066440b14
ENV PATH=/opt/bitnami/$BITNAMI_APP_NAME/sbin:/opt/bitnami/$BITNAMI_APP_NAME/bin:$PATH

# From bitnami-docker-mongodb/rootfs/app-entrypoint.sh
RUN harpoon initialize $BITNAMI_APP_NAME \
    ${MONGODB_ROOT_PASSWORD:+--rootPassword $MONGODB_ROOT_PASSWORD} \
    ${MONGODB_USER:+--username $MONGODB_USER} \
    ${MONGODB_PASSWORD:+--password $MONGODB_PASSWORD} \
    ${MONGODB_DATABASE:+--database $MONGODB_DATABASE} \
    ${MONGODB_REPLICASET_MODE:+--replicaSetMode $MONGODB_REPLICASET_MODE} \
    ${MONGODB_REPLICASET_NAME:+--replicaSetName $MONGODB_REPLICASET_NAME} \
    ${MONGODB_PRIMARY_HOST:+--primaryHost $MONGODB_PRIMARY_HOST} \
    ${MONGODB_PRIMARY_PORT:+--primaryPort $MONGODB_PRIMARY_PORT} \
    ${MONGODB_PRIMARY_USER:+--primaryUser $MONGODB_PRIMARY_USER} \
    ${MONGODB_PRIMARY_PASSWORD:+--primaryPassword $MONGODB_PRIMARY_PASSWORD}

#
# Eclipse Che
#
ENV BITNAMI_APP_NAME=express-che

USER bitnami
WORKDIR /projects

# From docker-compose.yml
ENV DATABASE_URL=mongodb://localhost:27017/my_project_development

CMD ["sudo", "-i", "harpoon", "start", "--foreground", "mongodb"]
