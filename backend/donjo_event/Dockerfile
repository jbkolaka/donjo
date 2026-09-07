FROM golang:1.26-alpine AS build
RUN apk add --no-cache alpine-sdk

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux go build -o main cmd/api/main.go

FROM alpine:3.21 AS prod
WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata
COPY --from=build /app/main /app/main
COPY --from=build /app/migrations /app/migrations
EXPOSE ${PORT}
CMD ["./main"]