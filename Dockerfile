FROM gcr.io/stacksmith-images/minideb:jessie-r8

MAINTAINER Bitnami <containers@bitnami.com>

ENV BITNAMI_APP_NAME=express-unify \
    BITNAMI_IMAGE_VERSION=4.14.0 \
    PATH=/opt/bitnami/node/bin:$PATH

# System packages required
RUN install_packages libc6 libssl1.0.0 libncurses5 libtinfo5 zlib1g libbz2-1.0 libreadline6 libstdc++6 libgcc1 ghostscript imagemagick libmysqlclient18
ENV PATH=/opt/bitnami/node/bin:/opt/bitnami/python/bin:$PATH \
    NODE_PATH=/opt/bitnami/node/lib/node_modules

# Additional modules required
RUN bitnami-pkg install node-6.9.4-0 --checksum aa0fe4923ece714285ed4ed63877e769b2bcf80c16d274d50db4d601541b64f4
RUN bitnami-pkg install express-generator-4.14.0-0 --checksum 7214212e41dab239184bf3cc75be3b73e4b4a07146e8274b933f0fa141ff12a5
RUN npm install -g bower@1.8.0 sequelize-cli

# Install express
RUN bitnami-pkg unpack express-4.14.0-2 --checksum bcf8c9ea99839527de9ac954f40eb8ffba2ceea72fccb9e9db9386ceb21f87a4

# ExpressJS template
ENV BITNAMI_APP_NAME=express-unify
ENV BITNAMI_IMAGE_VERSION=4.14.0-r17

COPY rootfs /

# The extra files that we bundle should use the Bitnami User
# so the entrypoint does not have any permission issues
RUN chown -R bitnami: /dist

VOLUME ["/app"]

#USER bitnami

WORKDIR /app
EXPOSE 3000

ENTRYPOINT ["/app-entrypoint.sh"]

CMD ["nami","start","--foreground","express"]
