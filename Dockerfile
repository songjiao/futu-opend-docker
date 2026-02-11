FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/futu-opend

# Download and extract OpenD (build-time, baked into image)
RUN wget -q -O opend.tar.gz "https://www.futunn.com/download/fetch-lasted-link?name=opend-ubuntu" && \
    tar xzf opend.tar.gz && \
    # Locate the CLI binary dir (double-nested, version in dir name)
    OPEND_DIR=$(find . -name "FutuOpenD" -type f -not -path "*GUI*" -exec dirname {} \;) && \
    mv "$OPEND_DIR"/* . && \
    rm -rf Futu_OpenD_* opend.tar.gz && \
    chmod +x FutuOpenD

COPY entrypoint.sh /opt/futu-opend/entrypoint.sh
RUN chmod +x /opt/futu-opend/entrypoint.sh

EXPOSE 11111

ENTRYPOINT ["/opt/futu-opend/entrypoint.sh"]
