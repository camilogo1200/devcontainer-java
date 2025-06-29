# syntax=docker/dockerfile:1

###############################################################################
#  📦 BASE IMAGE: Ubuntu Latest                                               #
###############################################################################
FROM ubuntu:latest
#FROM 	buildpack-deps:bookworm-curl

LABEL maintainer="cristhian.gomez@getinsured.com"
LABEL description="DevContainer with Java 17 (Corretto), Tomcat 11, Node 20, Maven 3.9.10, Python 3, and CLI tools."

ENV DEBIAN_FRONTEND=noninteractive

###############################################################################
#  🔧 INSTALL CORE UTILITIES & SYSTEM DEPENDENCIES                            #
###############################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
  bash curl wget zip unzip gzip tar rsync sudo gnupg lsb-release \
  ca-certificates software-properties-common openssh-client sshpass \
  python3 python3-pip git git-lfs build-essential coreutils \
  && rm -rf /var/lib/apt/lists/* \
  && git lfs install --system

###############################################################################
#  🟩 INSTALL NODE.JS 20 & NPM FROM OFFICIAL NODESOURCE REPO                  #
###############################################################################
# This ensures the latest stable release using official binaries
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
  && sudo apt-get update && sudo apt-get upgrade -y \
  && sudo apt-get install -y nodejs

###############################################################################
#  🧰 INSTALL MAVEN 3.9.10                                                     #
###############################################################################
ARG MAVEN_VERSION=3.9.10
ENV MAVEN_HOME=/opt/apache-maven-${MAVEN_VERSION}
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
  | tar -xzC /opt \
  && ln -s "${MAVEN_HOME}/bin/mvn" /usr/local/bin/mvn

###############################################################################
#  👤 CREATE NON-ROOT DEV USER                                                #
###############################################################################
ARG USERNAME=dev
ARG USER_UID=2000
ARG USER_GID=$USER_UID

# ─────────────────────────────────────────────────────────────────────────────
# Create group if GID does not exist, fallback to existing group if conflict
# ─────────────────────────────────────────────────────────────────────────────
RUN if ! getent group ${USER_GID} >/dev/null; then \
  groupadd --gid ${USER_GID} ${USERNAME}; \
  else \
  echo "⚠️ Group GID ${USER_GID} already exists. Reusing..."; \
  fi && \
  if ! id -u ${USER_UID} >/dev/null 2>&1; then \
  useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME}; \
  else \
  echo "⚠️ User UID ${USER_UID} already exists. Skipping useradd."; \
  fi


# ─────────────────────────────────────────────────────────────────────────────
#  📁 Copy Maven settings.xml into /workspaces/.m2
# ─────────────────────────────────────────────────────────────────────────────
ARG USERNAME
USER root
COPY .m2/settings.xml /home/${USERNAME}/.m2/settings.xml
COPY .m2/settings.xml /home/dev/.m2/settings.xml
COPY .m2/settings.xml /workspaces/.m2/settings.xml
RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.m2

###############################################################################
#  📦 INSTALL SDKMAN!, Amazon Corretto 17, and Tomcat 11 via SDKMAN!         #
###############################################################################
ARG USERNAME
ENV SDKMAN_DIR="/home/${USERNAME}/.sdkman"
ENV PATH="${SDKMAN_DIR}/bin:${SDKMAN_DIR}/candidates/tomcat/current/bin:${PATH}"

RUN curl -s "https://get.sdkman.io" | bash \
  && bash -c "source ${SDKMAN_DIR}/bin/sdkman-init.sh && \
  sdk install java 17.0.11-amzn && \
  sdk install tomcat 11.0.6"

# ───────────────────────────────────────────────────────────────────────────────
#  ➡️  Persist JAVA_HOME and update PATH so every shell—interactive or CI—has it
# ───────────────────────────────────────────────────────────────────────────────
ENV JAVA_HOME="${SDKMAN_DIR}/candidates/java/current"
ENV TOMCAT_HOME="${SDKMAN_DIR}/candidates/tomcat/current"
ENV PATH="$JAVA_HOME/bin:${TOMCAT_HOME}/bin:${PATH}"

ARG USERNAME
USER $USERNAME

# Add SDKMAN! init to shell environments
RUN echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> ~/.bashrc && \
  echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> ~/.bashrc

RUN echo 'export JAVA_HOME="$HOME/.sdkman/candidates/java/current"' >> ~/.bashrc \
  && echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc

RUN echo 'MAVEN_CONFIG="-s /workspaces/.m2/settings.xml"' >> /home/dev/.mavenrc \
  && chown dev:dev /home/dev/.mavenrc

RUN echo 'export CATALINA_HOME="$HOME/.sdkman/candidates/tomcat/current"' >> ~/.bashrc \
  && echo 'export PATH="$CATALINA_HOME/bin:$PATH"' >> ~/.bashrc

# Add SSH key (pass via build secrets or ARGs securely)
USER root
COPY .ssh/id_ed25519 /tmp/id_ed25519
COPY .ssh/known_hosts /tmp/known_hosts
RUN mkdir -p ~/.ssh && \
  mv /tmp/id_ed25519 ~/.ssh/id_ed25519 && \
  mv /tmp/known_hosts ~/.ssh/known_hosts && \
  chmod 600 ~/.ssh/id_ed25519 && \
  chmod 600 ~/.ssh/known_hosts
#ssh-keyscan bitbucket.com >> ~/.ssh/known_hosts

###############################################################################
#  🛠️ POST-BUILD SCRIPT                                                      #
###############################################################################

USER root
COPY scripts/post-setup.sh /tmp/post-setup.sh
RUN chmod +x /tmp/post-setup.sh && /tmp/post-setup.sh && rm /tmp/post-setup.sh

###############################################################################
#  🚀 ENTRYPOINT WRAPPER                                                     #
###############################################################################
USER root
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ARG USERNAME
USER root
RUN chown -R ${USERNAME}:${USERNAME} /workspaces

###############################################################################
#  📂 WORKDIR, VOLUME, HEALTHCHECK                                           #
###############################################################################
VOLUME ["/workspaces/.m2"]

HEALTHCHECK --interval=30s --timeout=10s \
  CMD java -version && node -v && mvn -v || exit 1

ARG USERNAME
USER $USERNAME
WORKDIR /workspaces/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
