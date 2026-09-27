# Etapa 1: Build
FROM php:8.2-alpine AS builder
WORKDIR /var/www/html
# Copia todo el contenido de src/ directamente al directorio de trabajo
COPY src/ .

# Etapa 2: Runner (Producción)
FROM php:8.2-alpine AS runner

# Instalar curl para el Healthcheck
RUN apk add --no-cache curl

WORKDIR /var/www/html

# Copiar archivos procesados desde el builder
COPY --from=builder /var/www/html /var/www/html

# Crear grupo y usuario no-root, y darle propiedad de los archivos
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && chown -R appuser:appgroup /var/www/html

USER appuser

EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD curl -f http://localhost:8000/health.php || exit 1

# Servidor de desarrollo integrado escuchando en el puerto 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "/var/www/html"]