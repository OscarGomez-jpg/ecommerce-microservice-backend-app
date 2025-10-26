# AWS K3s Deployment Guide

Guía completa para desplegar los 6 microservicios en AWS usando k3s para el Taller 2.

## Información General

**Duración recomendada:** 72 horas
**Costo estimado:** $1.66 USD
**Tipo de instancia:** t2.small (2GB RAM, 1 vCPU)
**Costo por hora:** $0.023 USD

## Requisitos Previos

### 1. AWS CLI Configurado

Verifica que AWS CLI esté instalado y configurado:

```bash
aws --version
aws sts get-caller-identity
```

Si no está configurado, ejecuta:

```bash
aws configure
```

E ingresa:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (recomendado: us-east-1)
- Default output format: json

### 2. Permisos Requeridos

Tu cuenta AWS necesita permisos para:
- EC2: crear/terminar instancias, security groups, key pairs
- EBS: crear/eliminar volúmenes
- VPC: acceso básico de red

### 3. Límites de Free Tier

Verifica que no hayas excedido:
- 750 horas de instancias t2.micro por mes (pero usaremos t2.small)
- 30 GB de almacenamiento EBS

## Flujo de Trabajo Completo

### Paso 1: Desplegar el Cluster

```bash
cd /home/osgomez/Code/icesi_codes/8vo_semestre/ingesoft_V/taller_2/ecommerce-microservice-backend-app

chmod +x scripts/aws-k3s-deploy.sh
./scripts/aws-k3s-deploy.sh
```

**Tiempo estimado:** 5-10 minutos

El script automáticamente:
1. Crea una instancia EC2 t2.small
2. Configura security groups con los puertos necesarios
3. Genera y configura SSH key pair
4. Instala k3s
5. Despliega los 6 microservicios
6. Configura NodePort para acceso externo

**Salida esperada:**

```
==============================================
Deployment Completo!
==============================================

Información de acceso guardada en: ~/.aws-k3s-deployment.conf

Instance ID: i-0123456789abcdef0
IP Pública: 54.123.45.67
Región: us-east-1

Acceso SSH:
  ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@54.123.45.67

URLs de servicios (disponibles en ~2-3 minutos):
  - Eureka Dashboard: http://54.123.45.67:30761
  - API Gateway: http://54.123.45.67:30080
  - Zipkin UI: http://54.123.45.67:30411

Verifica el estado con:
  ./scripts/aws-k3s-status.sh

IMPORTANTE: Recuerda eliminar el deployment cuando termines:
  ./scripts/aws-k3s-destroy.sh
```

### Paso 2: Verificar el Deployment

Espera 2-3 minutos para que los servicios inicien, luego verifica:

```bash
./scripts/aws-k3s-status.sh
```

**Salida esperada:**

```
==============================================
Estado del Deployment K3S
==============================================

Información básica:
  Instance ID: i-0123456789abcdef0
  IP Pública: 54.123.45.67
  Región: us-east-1
  Desplegado: 2025-10-21 10:00:00

Tiempo activo:
  Horas: 0.05
  Costo acumulado: $0.00 USD
  Costo proyectado 72h: $1.66 USD

Estado de la instancia EC2:
  ✓ Instancia RUNNING

Estado de los pods (esto puede tardar un momento)...
NAME                              READY   STATUS    RESTARTS   AGE
service-discovery-...             1/1     Running   0          2m
api-gateway-...                   1/1     Running   0          2m
user-service-...                  1/1     Running   0          2m
product-service-...               1/1     Running   0          2m
order-service-...                 1/1     Running   0          2m
zipkin-...                        1/1     Running   0          2m

Servicios disponibles:
  - Eureka Dashboard: http://54.123.45.67:30761
  - API Gateway: http://54.123.45.67:30080
```

### Paso 3: Acceder a los Servicios

#### Eureka Dashboard

Abre en tu navegador: `http://[TU-IP-PUBLICA]:30761`

Deberías ver los 6 servicios registrados:
- SERVICE-DISCOVERY
- API-GATEWAY
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE
- ZIPKIN

#### API Gateway

Abre en tu navegador: `http://[TU-IP-PUBLICA]:30080`

Endpoints disponibles:
```bash
# Listar productos
curl http://[TU-IP-PUBLICA]:30080/api/products

# Listar usuarios
curl http://[TU-IP-PUBLICA]:30080/api/users

# Listar órdenes
curl http://[TU-IP-PUBLICA]:30080/api/orders
```

#### Zipkin Tracing

Abre en tu navegador: `http://[TU-IP-PUBLICA]:30411`

Aquí puedes ver las trazas distribuidas entre los microservicios.

### Paso 4: Conectarse vía SSH (Opcional)

Si necesitas acceder directamente a la instancia:

```bash
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[TU-IP-PUBLICA]
```

Comandos útiles dentro de la instancia:

```bash
# Ver todos los pods
sudo k3s kubectl get pods -n ecommerce

# Ver logs de un servicio
sudo k3s kubectl logs -n ecommerce [POD-NAME]

# Ver descripción de un pod
sudo k3s kubectl describe pod -n ecommerce [POD-NAME]

# Ver uso de recursos
sudo k3s kubectl top pods -n ecommerce
```

### Paso 5: Monitoreo Durante las 72 Horas

Ejecuta periódicamente para monitorear costos:

```bash
./scripts/aws-k3s-status.sh
```

Esto te mostrará:
- Horas activas
- Costo acumulado actual
- Costo proyectado para 72 horas
- Estado de los pods

### Paso 6: Eliminar el Deployment

**MUY IMPORTANTE:** Cuando termines (máximo 72 horas), elimina todos los recursos:

```bash
./scripts/aws-k3s-destroy.sh
```

El script pedirá confirmación. Escribe exactamente: `ELIMINAR`

**Salida esperada:**

```
==============================================
ADVERTENCIA: Eliminación de Recursos AWS
==============================================

Esto eliminará PERMANENTEMENTE:
  - Instancia EC2: i-0123456789abcdef0
  - Security Group: ecommerce-k3s-sg
  - Key Pair: ecommerce-k3s-key
  - Archivos locales de configuración

Costo acumulado hasta ahora: $1.23 USD

Para confirmar, escribe exactamente: ELIMINAR
> ELIMINAR

Terminando instancia i-0123456789abcdef0...
✓ Instancia terminada

Esperando terminación completa...
✓ Instancia completamente terminada

Eliminando Security Group...
✓ Security Group eliminado

Eliminando Key Pair...
✓ Key Pair eliminado

Limpiando archivos locales...
✓ Archivos locales eliminados

==============================================
Cleanup Completo
==============================================

Verifica que no hay recursos activos con:
  ./scripts/aws-k3s-verify.sh
```

### Paso 7: Verificar No Hay Costos Residuales

Después de eliminar, verifica:

```bash
./scripts/aws-k3s-verify.sh
```

**Salida esperada (sin recursos activos):**

```
==============================================
Verificación de Recursos AWS
==============================================

Región: us-east-1

Instancias EC2:
  ✓ No hay instancias running
  ✓ No hay instancias stopped
  ✓ Costo actual: $0.00/hora

Security Groups (ecommerce-k3s-*):
  ✓ No hay security groups residuales

Key Pairs (ecommerce-k3s-*):
  ✓ No hay key pairs residuales

Volúmenes EBS huérfanos:
  ✓ No hay volúmenes huérfanos

==============================================
Estado: SIN RECURSOS ACTIVOS
==============================================

No hay recursos generando costos.
```

## Troubleshooting

### Problema 1: Pods en estado "Pending" o "CrashLoopBackOff"

**Causa:** Recursos insuficientes o servicios no listos

**Solución:**

```bash
# Conectarse a la instancia
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[TU-IP-PUBLICA]

# Ver descripción detallada del pod
sudo k3s kubectl describe pod -n ecommerce [POD-NAME]

# Ver logs del pod
sudo k3s kubectl logs -n ecommerce [POD-NAME]

# Ver uso de recursos
sudo k3s kubectl top pods -n ecommerce
```

Si hay falta de recursos, considera reducir réplicas:

```bash
sudo k3s kubectl scale deployment [SERVICE-NAME] --replicas=0 -n ecommerce
```

### Problema 2: No puedo acceder a Eureka/API Gateway

**Causa:** Puertos NodePort no accesibles o Security Group mal configurado

**Verificaciones:**

1. Verifica que la instancia esté corriendo:
```bash
aws ec2 describe-instances --instance-ids [INSTANCE-ID] \
  --query 'Reservations[0].Instances[0].State.Name'
```

2. Verifica el Security Group:
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ecommerce-k3s-sg" \
  --query 'SecurityGroups[0].IpPermissions'
```

3. Verifica que los servicios estén corriendo:
```bash
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[TU-IP-PUBLICA] \
  "sudo k3s kubectl get svc -n ecommerce"
```

### Problema 3: Los servicios no se registran en Eureka

**Causa:** Configuración incorrecta de Eureka o red

**Solución:**

```bash
# Ver logs del servicio problemático
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[TU-IP-PUBLICA] \
  "sudo k3s kubectl logs -n ecommerce -l app=[SERVICE-NAME]"

# Verificar variable de entorno EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[TU-IP-PUBLICA] \
  "sudo k3s kubectl get deployment [SERVICE-NAME] -n ecommerce -o yaml | grep -A5 env:"
```

Debería mostrar:
```yaml
env:
- name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
  value: "http://service-discovery:8761/eureka"
```

### Problema 4: Costo mayor al esperado

**Causa:** Instancia corriendo más tiempo del planeado

**Solución:**

```bash
# Ver tiempo activo y costo
./scripts/aws-k3s-status.sh

# Si excede 72 horas, eliminar inmediatamente
./scripts/aws-k3s-destroy.sh
```

### Problema 5: Script de deployment falla

**Errores comunes:**

1. **"UnauthorizedOperation"**
   - Causa: Credenciales AWS incorrectas o sin permisos
   - Solución: Verifica `aws sts get-caller-identity`

2. **"InvalidKeyPair.Duplicate"**
   - Causa: Key pair ya existe de deployment anterior
   - Solución:
   ```bash
   aws ec2 delete-key-pair --key-name ecommerce-k3s-key
   rm ~/.ssh/ecommerce-k3s-key.pem
   ```

3. **"VcpuLimitExceeded"**
   - Causa: Límite de vCPUs alcanzado
   - Solución: Termina instancias antiguas o solicita aumento de límite

4. **"InstanceLimitExceeded"**
   - Causa: Límite de instancias alcanzado
   - Solución: Termina instancias que no uses

## Monitoreo de Costos

### Cálculo Manual

```
Costo por hora: $0.023
Horas activas: [Ver en aws-k3s-status.sh]
Costo acumulado = Horas × $0.023
```

### Alertas Recomendadas

Configura una alerta en AWS Billing:

1. Ve a AWS Console → Billing → Billing preferences
2. Activa "Receive Billing Alerts"
3. Ve a CloudWatch → Alarms → Create alarm
4. Métrica: Billing → Total Estimated Charge
5. Umbral: $3.00 USD
6. Acción: Enviar email

Esto te alertará si excedes el costo esperado.

### Timeline de Costos

```
8 horas:   $0.18
24 horas:  $0.55
48 horas:  $1.10
72 horas:  $1.66 (objetivo)
100 horas: $2.30
168 horas: $3.86 (1 semana)
```

## Arquitectura Desplegada

```
EC2 t2.small (2GB RAM, 1 vCPU)
├── k3s server (~200MB)
│
├── Namespace: ecommerce
│   ├── service-discovery (Eureka)
│   │   └── NodePort: 30761
│   │   └── Memoria: 300-400MB
│   │
│   ├── api-gateway
│   │   └── NodePort: 30080
│   │   └── Memoria: 300-400MB
│   │
│   ├── zipkin
│   │   └── NodePort: 30411
│   │   └── Memoria: 200-300MB
│   │
│   ├── user-service
│   │   └── ClusterIP: 8700
│   │   └── Memoria: 250-350MB
│   │
│   ├── product-service
│   │   └── ClusterIP: 8500
│   │   └── Memoria: 250-350MB
│   │
│   └── order-service
│       └── ClusterIP: 8300
│       └── Memoria: 250-350MB
│
└── Total: ~1.8GB (deja ~200MB libres)
```

## Recursos Optimizados

Cada microservicio está configurado con:

```yaml
env:
- name: JAVA_OPTS
  value: "-Xmx256m -Xms128m"

resources:
  requests:
    memory: "250Mi"
    cpu: "100m"
  limits:
    memory: "350Mi"
    cpu: "200m"
```

Esto permite que 6 servicios corran en 2GB de RAM.

## Comandos de Referencia Rápida

```bash
# Desplegar
./scripts/aws-k3s-deploy.sh

# Ver estado
./scripts/aws-k3s-status.sh

# Eliminar
./scripts/aws-k3s-destroy.sh

# Verificar cleanup
./scripts/aws-k3s-verify.sh

# Conectarse vía SSH
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[IP-PUBLICA]

# Ver pods
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[IP-PUBLICA] \
  "sudo k3s kubectl get pods -n ecommerce"

# Ver logs
ssh -i ~/.ssh/ecommerce-k3s-key.pem ubuntu@[IP-PUBLICA] \
  "sudo k3s kubectl logs -n ecommerce [POD-NAME]"
```

## Checklist Pre-Deployment

- [ ] AWS CLI configurado (`aws sts get-caller-identity`)
- [ ] Región seleccionada (recomendado: us-east-1)
- [ ] Permisos EC2 verificados
- [ ] No hay key pairs conflictivos (`aws ec2 describe-key-pairs`)
- [ ] Scripts tienen permisos de ejecución (`chmod +x scripts/*.sh`)
- [ ] Tienes tiempo para monitorear el deployment (10 minutos)

## Checklist Post-Deployment

- [ ] Instancia EC2 corriendo (`aws-k3s-status.sh`)
- [ ] 6 pods en estado "Running"
- [ ] Eureka accesible en puerto 30761
- [ ] API Gateway accesible en puerto 30080
- [ ] 6 servicios registrados en Eureka Dashboard
- [ ] Zipkin UI accesible en puerto 30411

## Checklist Pre-Destroy

- [ ] Has capturado screenshots para documentación
- [ ] Has exportado logs si los necesitas
- [ ] Has respaldado datos importantes
- [ ] Confirmas que ya no necesitas el cluster
- [ ] Entiendes que la eliminación es PERMANENTE

## Checklist Post-Destroy

- [ ] Instancia terminada (`aws-k3s-verify.sh`)
- [ ] Security groups eliminados
- [ ] Key pairs eliminados
- [ ] No hay volúmenes EBS huérfanos
- [ ] Costo por hora = $0.00

## Preguntas Frecuentes

### ¿Puedo usar t2.micro en lugar de t2.small?

No. t2.micro solo tiene 1GB de RAM, insuficiente para 6 microservicios. El mínimo es t2.small con 2GB.

### ¿Puedo reducir costos usando menos servicios?

Sí. Si solo necesitas probar algunos servicios, modifica el script `aws-k3s-deploy.sh` y comenta los servicios que no necesites.

### ¿Qué pasa si olvido eliminar el deployment?

Seguirás pagando $0.023/hora. Después de 30 días: $16.56. Después de 1 año: $201.48.

### ¿Puedo pausar la instancia para ahorrar costos?

Sí, pero:
- Parada: Solo pagas EBS (~$0.10/mes), no compute
- Necesitas reiniciar k3s al volver a iniciar
- No es recomendado para deployments temporales

### ¿Funciona en otras regiones además de us-east-1?

Sí. El script usa la región configurada en AWS CLI. Cambiar región:

```bash
aws configure set region us-west-2
```

### ¿Puedo acceder desde cualquier IP?

Sí. El Security Group permite acceso desde 0.0.0.0/0. Para mayor seguridad, modifica `aws-k3s-deploy.sh` y cambia a tu IP:

```bash
--cidr YOUR_IP/32
```

## Comparación: k3s vs EKS

| Característica | k3s en EC2 | EKS |
|----------------|------------|-----|
| Costo (72h) | $1.66 | $226.00 |
| Setup | 5-10 min | 15-30 min |
| RAM requerida | 2GB | 4GB+ |
| Producción | No | Sí |
| Académico | ✓ Ideal | Overkill |
| Complejidad | Baja | Alta |

## Soporte

Si encuentras problemas:

1. Revisa la sección Troubleshooting
2. Verifica logs con `aws-k3s-status.sh`
3. Revisa `~/.aws-k3s-deployment.conf` para detalles del deployment
4. Consulta documentación oficial de k3s: https://k3s.io

## Referencias

- [k3s Documentation](https://docs.k3s.io/)
- [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
