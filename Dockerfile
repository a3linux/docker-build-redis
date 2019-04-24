FROM a3linux/docker-ubuntu-build:latest

WORKDIR /build

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD [""]
