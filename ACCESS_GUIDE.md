# Guia de Acceso a Interfaces de los Microservicios

Este proyecto es un **backend de microservicios** (no tiene frontend tradicional), pero tiene varias interfaces visuales para interactuar con los servicios.

## Paso 1: Desplegar los Microservicios

Primero debes desplegar. Elige una opcion:

### Opcion A: Docker Compose (Mas facil)
```bash
./scripts/deploy-docker-compose.sh
```

### Opcion B: Minikube (Kubernetes local)
```bash
./scripts/deploy-local.sh
```

---

## Interfaces Visuales Disponibles

### 1. Eureka Dashboard (Service Discovery)

**Que es:** Panel para ver todos los microservicios registrados y su estado

**Docker Compose:**
```
URL: http://localhost:8761
```

**Minikube:**
```bash
kubectl port-forward svc/service-discovery 8761:8761 -n dev
```
Luego abre: http://localhost:8761

**Captura:**
- Veras todos los servicios registrados
- Estado de salud de cada servicio
- Instancias disponibles

---

### 2. Swagger UI (APIs Interactivas)

**Que es:** Documentacion interactiva de APIs donde puedes probar endpoints

#### Proxy Client API (Gateway principal)
**Docker Compose:**
```
URL: http://localhost:8900/swagger-ui.html
```

**Minikube:**
```bash
kubectl port-forward svc/proxy-client 8900:8900 -n dev
```
Luego abre: http://localhost:8900/swagger-ui.html

#### User Service API
**Docker Compose:**
```
URL: http://localhost:8700/swagger-ui.html
```

**Minikube:**
```bash
kubectl port-forward svc/user-service 8700:8700 -n dev
```
Luego abre: http://localhost:8700/swagger-ui.html

#### Otros servicios con Swagger (mismo patron):
- Product Service: http://localhost:8500/swagger-ui.html
- Order Service: http://localhost:8300/swagger-ui.html
- Payment Service: http://localhost:8400/swagger-ui.html
- Shipping Service: http://localhost:8600/swagger-ui.html
- Favourite Service: http://localhost:8800/swagger-ui.html

**Que puedes hacer en Swagger:**
- Ver todos los endpoints disponibles
- Probar APIs directamente desde el navegador
- Ver esquemas de request/response
- Ejecutar operaciones CRUD

---

### 3. Zipkin (Distributed Tracing)

**Que es:** Panel para rastrear requests a traves de multiples microservicios

**Docker Compose:**
```
URL: http://localhost:9411
```

**Minikube:**
```bash
kubectl port-forward svc/zipkin 9411:9411 -n dev
```
Luego abre: http://localhost:9411

**Que puedes hacer:**
- Ver el flujo de una peticion a traves de multiples servicios
- Identificar cuellos de botella
- Ver tiempos de respuesta

---

### 4. API Gateway

**Que es:** Punto de entrada unificado a todos los microservicios

**Docker Compose:**
```
URL: http://localhost:8080
```

**Minikube:**
```bash
kubectl port-forward svc/api-gateway 8080:8080 -n dev
```

**Endpoints disponibles:**
```bash
# Health check
curl http://localhost:8080/actuator/health

# Productos
curl http://localhost:8080/api/products

# Usuarios
curl http://localhost:8080/api/users

# Ordenes
curl http://localhost:8080/api/orders
```

---

### 5. Spring Boot Actuator (Metricas)

Cada servicio expone metricas en `/actuator`

**Ejemplos:**
```bash
# Health check
curl http://localhost:8700/actuator/health

# Metricas
curl http://localhost:8700/actuator/metrics

# Info
curl http://localhost:8700/actuator/info

# Prometheus metrics
curl http://localhost:8700/actuator/prometheus
```

---

## Flujo Recomendado para Explorar

### 1. Primero - Ver servicios registrados
Abre Eureka Dashboard: http://localhost:8761
- Verifica que todos los servicios esten UP

### 2. Luego - Explorar APIs
Abre Swagger de Proxy Client: http://localhost:8900/swagger-ui.html
- Prueba endpoints de usuarios, productos, etc.

### 3. Finalmente - Ver tracing
Abre Zipkin: http://localhost:9411
- Ejecuta algunas operaciones en Swagger
- Luego ve el trace en Zipkin

---

## Probar con Postman o cURL

### Ejemplo 1: Obtener todos los productos
```bash
curl http://localhost:8080/api/products
```

### Ejemplo 2: Crear un usuario
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Juan",
    "lastName": "Perez",
    "email": "juan@example.com",
    "phone": "1234567890"
  }'
```

### Ejemplo 3: Crear una orden
```bash
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderDesc": "Mi primera orden",
    "orderDate": "2024-01-15T10:30:00"
  }'
```

---

## Acceso en Minikube - Comandos Rapidos

Si desplegaste en Minikube, usa estos port-forwards:

```bash
# Terminal 1 - Eureka
kubectl port-forward svc/service-discovery 8761:8761 -n dev

# Terminal 2 - API Gateway
kubectl port-forward svc/api-gateway 8080:8080 -n dev

# Terminal 3 - Swagger Proxy
kubectl port-forward svc/proxy-client 8900:8900 -n dev

# Terminal 4 - Zipkin
kubectl port-forward svc/zipkin 9411:9411 -n dev
```

**Tip:** Abre multiples terminales o usa `screen`/`tmux`

---

## Ver Estado de Despliegue

### Docker Compose
```bash
docker compose ps
docker compose logs -f user-service
```

### Minikube
```bash
kubectl get pods -n dev
kubectl get svc -n dev
kubectl logs -f deployment/user-service -n dev
```

---

## Troubleshooting

### No puedo acceder a Swagger
1. Verifica que el servicio este corriendo:
   ```bash
   docker compose ps
   # o
   kubectl get pods -n dev
   ```

2. Verifica los logs:
   ```bash
   docker compose logs user-service
   # o
   kubectl logs deployment/user-service -n dev
   ```

3. Espera un poco mas (los servicios tardan ~30-60 segundos en iniciar)

### Puerto ya en uso
```bash
# Ver que esta usando el puerto
sudo lsof -i :8761

# Matar el proceso
sudo kill -9 <PID>
```

### Servicios no se registran en Eureka
- Espera 1-2 minutos (el heartbeat tarda)
- Verifica que service-discovery este corriendo
- Revisa los logs de los servicios

---

## Resumen de URLs (Docker Compose)

| Servicio | URL | Proposito |
|----------|-----|-----------|
| Eureka Dashboard | http://localhost:8761 | Ver servicios registrados |
| API Gateway | http://localhost:8080 | Punto de entrada unificado |
| Proxy Client Swagger | http://localhost:8900/swagger-ui.html | Probar APIs |
| User Service Swagger | http://localhost:8700/swagger-ui.html | APIs de usuarios |
| Product Service Swagger | http://localhost:8500/swagger-ui.html | APIs de productos |
| Zipkin | http://localhost:9411 | Tracing distribuido |

---

## Frontend Personalizado (Opcional)

Si quieres crear un frontend, puedes:

1. Usar React/Vue/Angular consumiendo las APIs
2. Conectarte al API Gateway: http://localhost:8080
3. Ver los endpoints en Swagger para saber que APIs usar

**Ejemplo con fetch (JavaScript):**
```javascript
fetch('http://localhost:8080/api/products')
  .then(response => response.json())
  .then(data => console.log(data));
```
