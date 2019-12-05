FROM golang:1.13-alpine as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk bash git
RUN git clone https://github.com/monasuite/neutrino /go/src/github.com/monasuite/neutrino \
&&  cd /go/src/github.com/monasuite/neutrino \
&&  bash ./btcd_checkout.sh \
&&  RACE=false GO111MODULE=on PATH=$PATH:$GOPATH/bin go build

FROM alpine as monad
RUN apk add --no-cache git
WORKDIR /
RUN git clone https://github.com/monasuite/monad.git --depth=1

# Start a new, final image.
FROM pizzafactory0contorno/piatto:alpine

# Copy the binaries from the builder image.
COPY --from=builder /go/bin/monad /usr/local/bin/
COPY --from=monad /monad/sample-monad.conf /usr/local/bin/

# Define a root volume for data persistence.
RUN mkdir -p /home/user/.monad
VOLUME /home/user/.monad

# Expose RPC and P2P ports.
EXPOSE 9400 9401 9402 9403 19400 19401 19402 19403

# Specify the start command and entrypoint as the monad daemon.
CMD [ "/usr/local/bin/monad" ]

LABEL maintainer="monaka@pizzafactory.jp"
