FROM golang:1.26-alpine AS build
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o main cmd/api/main.go

FROM alpine:3.21 AS prod
WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata
COPY --from=build /app/main /app/main
EXPOSE ${PORT}
CMD ["./main"]