FROM docker:19.03.11 as runtime

RUN apk update \
  && apk upgrade \
  && apk add --no-cache \
  ca-certificates \
  git \
  jq \
  bash

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
