# Build stage
FROM golang:alpine AS build

WORKDIR /build

# Install git for go mod operations
# hadolint ignore=DL3018
RUN apk add --no-cache git

# Copy go modules files first for better caching
COPY go.mod go.sum ./

# Download dependencies (cached if go.mod/go.sum unchanged)
RUN go mod download

# Copy source code
COPY . .

# Build the binary with optimizations
# - CGO_ENABLED=0: Static binary for scratch image
# - ldflags "-s -w": Strip debug info to reduce binary size
RUN CGO_ENABLED=0 GOOS=linux go build -o freeradius_exporter -ldflags "-s -w"

# Final stage - minimal scratch image
FROM scratch

# Copy the binary from build stage
COPY --from=build /build/freeradius_exporter /freeradius_exporter

# Copy CA certificates for HTTPS requests
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Run as non-root user (nobody) for security
USER 65534

# Expose the default prometheus exporter port
EXPOSE 9812

# Command to run the exporter
ENTRYPOINT ["/freeradius_exporter"]
