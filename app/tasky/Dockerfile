FROM golang:1.26.5-bookworm AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/tasky ./main.go

FROM debian:bookworm-slim
WORKDIR /
COPY --from=builder /out/tasky /tasky
COPY wizexercise.txt /wizexercise.txt
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/tasky"]
