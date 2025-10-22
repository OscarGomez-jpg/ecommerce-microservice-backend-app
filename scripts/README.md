# Scripts de Despliegue

## Opciones de Despliegue Local

### Opcion 1: Docker Compose (Recomendado para inicio rapido)

**Requisitos:**
- Docker instalado
- Docker Compose instalado

**Comando:**
```bash
./scripts/deploy-docker-compose.sh
```

**Ventajas:**
- Mas rapido de configurar
- No requiere Kubernetes
- Ideal para desarrollo local

**Desventajas:**
- No simula ambiente de produccion
- No tiene auto-scaling
- No tiene health checks avanzados

---

### Opcion 2: Minikube (Simula Kubernetes local)

**Requisitos:**
- Docker instalado
- Minikube instalado
- kubectl instalado

**Instalacion de Minikube:**
```bash
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar
minikube version
```

**Instalacion de kubectl:**
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Verificar
kubectl version --client
```

**Comando:**
```bash
./scripts/deploy-local.sh
```

**Ventajas:**
- Simula ambiente de Kubernetes real
- Soporta auto-scaling (HPA)
- Health checks y probes
- Mejor para testing de pipelines

**Desventajas:**
- Requiere mas recursos (4 CPU, 8GB RAM)
- Configuracion mas compleja

---

### Opcion 3: AWS EKS (Produccion)

**Requisitos:**
- Cuenta AWS configurada
- AWS CLI instalado
- eksctl instalado
- kubectl instalado

**Comando:**
```bash
./scripts/deploy-aws.sh
```

**IMPORTANTE:**
- Esto creara recursos en AWS que pueden generar costos
- El Control Plane de EKS cuesta $0.10/hora (~$73/mes)
- Usa el script de cleanup cuando termines: `./scripts/cleanup-aws.sh`

---

## Comparacion Rapida

| Caracteristica | Docker Compose | Minikube | AWS EKS |
|---------------|----------------|----------|---------|
| Setup Time | 5-10 min | 15-20 min | 30-40 min |
| Recursos | Bajo | Medio | Alto |
| Costo | Gratis | Gratis | ~$73/mes |
| Auto-scaling | No | Si | Si |
| Load Balancer | No | Si (NodePort) | Si (ELB) |
| Produccion Ready | No | No | Si |

---

## Inicio Rapido

### Para Desarrollo Local:
```bash
./scripts/deploy-docker-compose.sh
```

### Para Testing de Kubernetes:
```bash
# Instalar minikube y kubectl primero
./scripts/deploy-local.sh
```

### Para Produccion:
```bash
# Configurar AWS primero (ver MANUAL_CONFIG.md)
./scripts/deploy-aws.sh
```

---

## Verificacion de Servicios

### Docker Compose:
```bash
# Ver estado
docker compose ps

# Ver logs
docker compose logs -f user-service

# Detener todo
docker compose down
```

### Kubernetes (Minikube/EKS):
```bash
# Ver pods
kubectl get pods -n dev

# Ver servicios
kubectl get svc -n dev

# Ver logs
kubectl logs -f deployment/user-service -n dev

# Port-forward para acceso local
kubectl port-forward svc/api-gateway 8080:8080 -n dev
```

---

## Troubleshooting

### Docker Compose no inicia servicios:
```bash
# Ver logs detallados
docker compose logs

# Reconstruir imagenes
docker compose build --no-cache
docker compose up -d
```

### Minikube no inicia:
```bash
# Eliminar y recrear
minikube delete
minikube start --cpus=4 --memory=8192

# Verificar estado
minikube status
```

### Pods en Kubernetes no arrancan:
```bash
# Ver eventos
kubectl get events -n dev --sort-by='.lastTimestamp'

# Describir pod
kubectl describe pod <pod-name> -n dev

# Ver logs
kubectl logs <pod-name> -n dev
```

---

## Pruebas Despues del Despliegue

### Docker Compose:
```bash
# Verificar API Gateway
curl http://localhost:8080/actuator/health

# Verificar Eureka
open http://localhost:8761

# Ver productos
curl http://localhost:8080/api/products
```

### Kubernetes:
```bash
# Port-forward primero
kubectl port-forward svc/api-gateway 8080:8080 -n dev

# Luego en otra terminal
curl http://localhost:8080/actuator/health
```

---

## Limpieza

### Docker Compose:
```bash
docker compose down
docker compose down -v  # Incluye volumes
```

### Minikube:
```bash
minikube delete
```

### AWS EKS:
```bash
./scripts/cleanup-aws.sh
```
