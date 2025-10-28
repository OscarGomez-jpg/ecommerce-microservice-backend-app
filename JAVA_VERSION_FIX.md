# 🔧 Corrección de Versión de Java

## Problema

SonarQube 25.9 (Community Edition) requiere **Java 17**, pero el proyecto y los contenedores usaban **Java 11**.

**Error original**:
```
java.lang.UnsupportedClassVersionError:
org/sonar/batch/bootstrapper/EnvironmentInformation
has been compiled by a more recent version of the Java Runtime
(class file version 61.0), this version of the Java Runtime
only recognizes class file versions up to 55.0
```

## Solución Aplicada

### 1. Jenkinsfile Actualizado

**Antes**:
```yaml
- name: maven
  image: maven:3.8-openjdk-11  # ❌ Java 11
```

**Después**:
```yaml
- name: maven
  image: maven:3.9-eclipse-temurin-17  # ✅ Java 17
```

### 2. Dockerfile Actualizado

**Antes**:
```dockerfile
FROM maven:3.8-openjdk-11 AS build
FROM openjdk:11-jre-slim
```

**Después**:
```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
FROM eclipse-temurin:17-jre-jammy
```

### 3. Compatibilidad

✅ **Java 17 es retrocompatible con Java 11**
- El código compilado para Java 11 funciona en Java 17
- Los microservicios seguirán funcionando correctamente
- No se requieren cambios en el código fuente

## Verificar la Corrección

### Ejecutar el Pipeline de Nuevo

```bash
# 1. Ir a Jenkins: http://192.168.49.2:30800
# 2. Ir a tu job: ecommerce-pipeline
# 3. Build with Parameters:
SERVICE_NAME: user-service
RUN_SONAR: true
DEPLOY_TO_MINIKUBE: false
# 4. Build
```

### Verificar Versión de Java en el Build

En los logs del pipeline deberías ver:
```
[INFO] Java 17.0.x Eclipse Adoptium (64-bit)
```

## Versiones de Java y SonarQube

| SonarQube Version | Java Requerido |
|-------------------|----------------|
| 25.x (latest)     | Java 17+       |
| 10.x - 24.x       | Java 17+       |
| 9.x               | Java 11+       |
| 8.x               | Java 11+       |

## Alternativa: Usar Versión Anterior de SonarQube

Si prefieres mantener Java 11, puedes hacer downgrade de SonarQube:

```bash
# Desinstalar SonarQube actual
helm uninstall sonarqube -n cicd

# Instalar versión compatible con Java 11
helm install sonarqube sonarqube/sonarqube \
  --namespace cicd \
  --set community.enabled=true \
  --set image.tag=9.9-community \
  --set monitoringPasscode=monitoring123 \
  -f sonarqube-values.yaml
```

Pero **NO recomendado** - es mejor usar Java 17 que es LTS y más actual.

## Referencias

- [SonarQube Requirements](https://docs.sonarqube.org/latest/requirements/requirements/)
- [Java Version Compatibility](https://docs.oracle.com/en/java/javase/17/migrate/migration-guide.html)
