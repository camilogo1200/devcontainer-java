# syntax=docker/dockerfile:1

###############################################################################
#  🌟 GLOBAL BUILD ARGUMENTS & CHECKSUMS  🌟
###############################################################################
ARG MAVEN_VERSION=3.9.10
# SHA-512 for apache-maven-3.9.10-bin.tar.gz  (from Apache download page)
ARG MAVEN_SHA=4ef617e421695192a3e9a53b3530d803baf31f4269b26f9ab6863452d833da5530a4d04ed08c36490ad0f141b55304bceed58dbf44821153d94ae9abf34d0e1b
# Exact Node 20 LTS package version for Alpine 3.19 (security-fixed)
ARG NODE_PKG_VERSION=20.15.1-r0

###############################################################################
#  🏗️  STAGE 1 – MAVEN BUILDER  (download + verify)                           #
###############################################################################
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine@sha256:070c3a37ea2465375014fbbdfbe0414d1e1a64339e1cc103d0059372bcc77647 AS maven-builder

# ────────  Install minimal tools needed for download / verification  ────────
RUN apk add --no-cache curl tar gnupg

# ────────  Bring in build args  ────────
ARG MAVEN_VERSION
ARG MAVEN_SHA

# ✨ Fetch Maven tarball, verify SHA-512, extract to /opt, then clean up ✨
RUN curl -fsSL "https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    -o /tmp/maven.tar.gz \
    && echo "${MAVEN_SHA}  /tmp/maven.tar.gz" | sha512sum -c - \
    && tar -xz -C /opt -f /tmp/maven.tar.gz \
    && rm /tmp/maven.tar.gz

###############################################################################
#  🎯  STAGE 2 – FINAL RUNTIME IMAGE                                           #
###############################################################################
FROM public.ecr.aws/amazoncorretto/amazoncorretto:17-alpine@sha256:070c3a37ea2465375014fbbdfbe0414d1e1a64339e1cc103d0059372bcc77647

LABEL maintainer="cristhian.gomez@getinsured.com" \
    description="DevContainer with Java 17, Maven, Node 20, Python 3, and essential CLI tools."

# ─────────────────────────────────────────────────────────────────────────────
#  📦  Install core utilities, Node 20, Python 3, Git-LFS, etc.
#      * --no-cache  ➜ keeps the layer slim (no local apk cache)
#      * Node pinned to ${NODE_PKG_VERSION} for reproducibility
# ─────────────────────────────────────────────────────────────────────────────
ARG NODE_PKG_VERSION
RUN apk add --no-cache \
    bash coreutils curl wget \
    git git-lfs openssh-client \
    zip unzip gzip tar rsync sudo openssl sshpass \
    python3 py3-pip ca-certificates gnupg \
    "nodejs=${NODE_PKG_VERSION}" npm \
    && git lfs install --system

# ─────────────────────────────────────────────────────────────────────────────
#  🏗️  COPY MAVEN FROM BUILDER STAGE
# ─────────────────────────────────────────────────────────────────────────────
ARG MAVEN_VERSION
COPY --from=maven-builder /opt/apache-maven-${MAVEN_VERSION} /opt/apache-maven-${MAVEN_VERSION}

# 📐  Configure environment paths & Maven local repo
ENV MAVEN_HOME=/opt/apache-maven-${MAVEN_VERSION}
ENV PATH="${MAVEN_HOME}/bin:${PATH}"
ENV MAVEN_OPTS="-Dmaven.repo.local=/workspace/.m2"

###############################################################################
#  🛠️  EXECUTE BUILD-TIME SCRIPT (post-setup.sh)                              #
###############################################################################
# 1.  Copy script into a temporary location
# 2.  Make it executable, run it, then delete to keep the image tidy
COPY post-setup.sh /tmp/post-setup.sh
RUN chmod +x /tmp/post-setup.sh \
    && /tmp/post-setup.sh \
    && rm /tmp/post-setup.sh

###############################################################################
#  👤  NON-ROOT DEVELOPER USER                                                 #
###############################################################################
ARG USERNAME=app
ARG USER_UID=1000
RUN adduser -D -u ${USER_UID} -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

###############################################################################
#  🚀  RUNTIME ENTRYPOINT WRAPPER (entrypoint.sh)                             #
###############################################################################
# The entrypoint runs at *every* container start, then hands control to CMD.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

###############################################################################
#  📂  WORKDIR & VOLUME                                                       #
###############################################################################
USER ${USERNAME}
WORKDIR /workspace
VOLUME ["/workspace/.m2"]   # persist Maven cache between container runs

###############################################################################
#  ❤️‍🩹  HEALTHCHECK                                                          #
###############################################################################
HEALTHCHECK --interval=30s --timeout=10s \
    CMD java -version && node -v && mvn -v || exit 1

###############################################################################
#  🏁  ENTRYPOINT + DEFAULT CMD                                               #
###############################################################################
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
