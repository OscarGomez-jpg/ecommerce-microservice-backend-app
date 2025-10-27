# Guía Completa: Configurar Jenkins Local y Ejecutar Pipeline DEV

Esta guía te permite configurar Jenkins en tu máquina local y ejecutar el pipeline DEV para obtener screenshots de ejecución exitosa.

**Tiempo estimado**: 30-45 minutos
**Requisitos**: Docker instalado y corriendo

---

## Paso 1: Limpiar Jenkins Anterior (Si Existe)

```bash
# Detener y eliminar contenedor Jenkins anterior
docker stop jenkins-local 2>/dev/null
docker rm jenkins-local 2>/dev/null

# Eliminar volumen anterior (opcional, para empezar fresco)
docker volume rm jenkins_home 2>/dev/null

# Verificar limpieza
docker ps -a | grep jenkins
```

**Resultado esperado**: No debería aparecer ningún contenedor jenkins.

---

## Paso 2: Iniciar Jenkins con Docker

```bash
docker run -d \
  --name jenkins-local \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/workspace \
  --user root \
  jenkins/jenkins:2.426.1-lts
```

**Explicación de parámetros**:
- `-d`: Modo detached (corre en background)
- `--name jenkins-local`: Nombre del contenedor
- `-p 8080:8080`: Puerto web de Jenkins
- `-p 50000:50000`: Puerto para agentes Jenkins
- `-v jenkins_home:/var/jenkins_home`: Persistencia de datos Jenkins
- `-v /var/run/docker.sock`: Permite a Jenkins usar Docker del host
- `-v "$PWD":/workspace`: Monta tu proyecto en /workspace
- `--user root`: Permisos para usar Docker socket
- `jenkins/jenkins:2.426.1-lts`: Imagen estable de Jenkins

**Esperar**: 60-90 segundos para que Jenkins inicie completamente.

---

## Paso 3: Verificar que Jenkins Está Corriendo

```bash
# Verificar estado del contenedor
docker ps | grep jenkins

# Debería mostrar:
# jenkins-local ... Up ... 0.0.0.0:8080->8080/tcp
```

**Si el contenedor no está UP**:
```bash
# Ver logs de error
docker logs jenkins-local

# Problema común: Permisos del socket Docker
# Solución: Reintentar sin socket Docker (limitado pero funcional)
docker run -d \
  --name jenkins-local \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:2.426.1-lts
```

---

## Paso 4: Obtener Contraseña Inicial de Jenkins

```bash
# Esperar a que Jenkins genere la contraseña (puede tardar 60-90 segundos)
sleep 60

# Obtener contraseña inicial
docker exec jenkins-local cat /var/jenkins_home/secrets/initialAdminPassword
```

**Resultado**: Una cadena alfanumérica como `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

**Copiar esta contraseña** - la necesitarás en el siguiente paso.

**Si da error "No such file"**: Jenkins aún está iniciando. Espera 30 segundos más:
```bash
sleep 30
docker exec jenkins-local cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## Paso 5: Acceder a Jenkins Web

1. Abrir navegador en: **http://localhost:8080**

2. Verás la pantalla "Unlock Jenkins"

3. Pegar la contraseña obtenida en Paso 4

4. Click "Continue"

**Screenshot a capturar**: Pantalla de desbloqueo con contraseña ingresada

---

## Paso 6: Instalar Plugins

En la pantalla "Customize Jenkins":

1. Seleccionar: **"Install suggested plugins"**

2. Esperar 5-10 minutos mientras se instalan plugins

**Plugins necesarios** (se instalan automáticamente):
- Git plugin
- Pipeline plugin
- Docker plugin
- Credentials plugin

**Screenshot a capturar**: Pantalla de instalación de plugins en progreso

---

## Paso 7: Crear Usuario Admin

Después de instalar plugins, aparecerá "Create First Admin User":

**Llenar formulario**:
- Username: `admin`
- Password: `admin123` (o la que prefieras)
- Full name: `Jenkins Admin`
- Email: `admin@localhost`

Click "Save and Continue"

**Screenshot a capturar**: Formulario de creación de usuario

---

## Paso 8: Configurar URL de Jenkins

En "Instance Configuration":

- Jenkins URL: `http://localhost:8080/`

Click "Save and Finish"

Click "Start using Jenkins"

**Screenshot a capturar**: Dashboard principal de Jenkins

---

## Paso 9: Instalar Plugin Docker (Adicional)

Si necesitas que Jenkins ejecute comandos Docker:

1. Click "Manage Jenkins" (menú izquierdo)

2. Click "Manage Plugins"

3. Pestaña "Available plugins"

4. Buscar: `Docker Pipeline`

5. Marcar checkbox "Docker Pipeline"

6. Click "Install without restart"

7. Marcar "Restart Jenkins when installation is complete and no jobs are running"

8. Esperar reinicio (2-3 minutos)

9. Refrescar navegador y volver a login con `admin/admin123`

---

## Paso 10: Configurar Credenciales de Docker Hub

Para que el pipeline pueda hacer push a Docker Hub:

1. En Dashboard, click **"Manage Jenkins"**

2. Click **"Manage Credentials"**

3. Click **"(global)"** domain

4. Click **"Add Credentials"** (botón derecho)

5. Llenar formulario:
   - Kind: `Username with password`
   - Scope: `Global`
   - Username: `TU_USUARIO_DOCKERHUB` (ej: selimhorri)
   - Password: `TU_PASSWORD_DOCKERHUB` o token
   - ID: `dockerhub-credentials`
   - Description: `Docker Hub credentials for pushing images`

6. Click "Create"

**Screenshot a capturar**: Lista de credenciales mostrando dockerhub-credentials

**IMPORTANTE**: Si no tienes cuenta Docker Hub:
- Crear en: https://hub.docker.com/signup
- O usar credenciales del repositorio original

---

## Paso 11: Crear Pipeline Job para DEV

1. En Dashboard, click **"New Item"** (menú izquierdo)

2. Llenar:
   - Enter an item name: `ecommerce-dev-pipeline`
   - Seleccionar: **Pipeline**
   - Click "OK"

**Screenshot a capturar**: Pantalla de creación de job

---

## Paso 12: Configurar Pipeline DEV

En la pantalla de configuración del job:

### Sección "General"

- Marcar checkbox: `This project is parameterized`
- Click "Add Parameter" → "Choice Parameter"
  - Name: `SERVICE`
  - Choices (uno por línea):
    ```
    user-service
    product-service
    order-service
    api-gateway
    service-discovery
    ```
  - Description: `Select the microservice to build`

### Sección "Pipeline"

- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: `/workspace` (la ruta donde montamos el proyecto)

  **Alternativa si no funciona**:
  - Definition: `Pipeline script`
  - Copiar el contenido de `jenkins/Jenkinsfile-dev` y pegarlo

**Script Path**: `jenkins/Jenkinsfile-dev`

- Click "Save"

**Screenshot a capturar**: Configuración del pipeline (secciones General y Pipeline)

---

## Paso 13: Modificar Jenkinsfile-dev para Ambiente Local

El Jenkinsfile actual asume que el proyecto está en un repo Git. Para local, necesitamos ajustes:

**Opción A - Usar Pipeline Script Directamente**:

Copiar el contenido de `jenkins/Jenkinsfile-dev` y pegarlo en la configuración del job (paso anterior), pero con estos cambios:

**Cambio 1**: Remover el stage 'Checkout' (ya no necesario):

```groovy
// COMENTAR O ELIMINAR ESTE STAGE
/*
stage('Checkout') {
    steps {
        git branch: 'develop', url: 'https://github.com/SelimHorri/ecommerce-microservice-backend-app.git'
    }
}
*/
```

**Cambio 2**: Actualizar paths para usar /workspace:

```groovy
stage('Build') {
    steps {
        dir("/workspace/${params.SERVICE}") {  // Cambiar de ${params.SERVICE} a /workspace/${params.SERVICE}
            sh '''
                echo "Building ${SERVICE} with Java 11 (Docker)..."
                docker run --rm \
                    -v "$(pwd)/..":/usr/src/app \
                    -v "$HOME/.m2":/root/.m2 \
                    -w /usr/src/app/${SERVICE} \
                    maven:3.8.6-openjdk-11 \
                    mvn clean package -DskipTests -Dmaven.test.skip=true
            '''
        }
    }
}
```

**Jenkinsfile-dev completo adaptado para local**:

```groovy
pipeline {
    agent any

    parameters {
        choice(
            name: 'SERVICE',
            choices: ['user-service', 'product-service', 'order-service', 'api-gateway', 'service-discovery'],
            description: 'Select the microservice to build'
        )
    }

    environment {
        DOCKER_USERNAME = 'selimhorri'  // Cambiar por tu usuario
        SERVICE = "${params.SERVICE}"
        GIT_COMMIT_SHORT = sh(script: "echo ${BUILD_NUMBER}", returnStdout: true).trim()
    }

    stages {
        stage('Build') {
            steps {
                dir("/workspace/${params.SERVICE}") {
                    sh '''
                        echo "Building ${SERVICE} with Java 11 (Docker)..."
                        docker run --rm \
                            -v "$(pwd)/..":/usr/src/app \
                            -v "$HOME/.m2":/root/.m2 \
                            -w /usr/src/app/${SERVICE} \
                            maven:3.8.6-openjdk-11 \
                            mvn clean package -DskipTests -Dmaven.test.skip=true
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir("/workspace/${params.SERVICE}") {
                    sh '''
                        echo "Running unit tests for ${SERVICE} with Java 11..."
                        docker run --rm \
                            -v "$(pwd)/..":/usr/src/app \
                            -v "$HOME/.m2":/root/.m2 \
                            -w /usr/src/app/${SERVICE} \
                            maven:3.8.6-openjdk-11 \
                            mvn test
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir("/workspace/${params.SERVICE}") {
                    sh '''
                        echo "Building Docker image for ${SERVICE}..."
                        docker build -t ${DOCKER_USERNAME}/${SERVICE}-ecommerce-boot:dev-${GIT_COMMIT_SHORT} \
                            -f Dockerfile .
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        sh "docker push ${DOCKER_USERNAME}/${SERVICE}-ecommerce-boot:dev-${GIT_COMMIT_SHORT}"
                    }
                }
            }
        }

        stage('Deploy to Dev (Docker Compose)') {
            steps {
                sh '''
                    echo "Deployment to local Docker Compose would happen here"
                    echo "Image ready: ${DOCKER_USERNAME}/${SERVICE}-ecommerce-boot:dev-${GIT_COMMIT_SHORT}"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully for ${SERVICE}!"
        }
        failure {
            echo "Pipeline failed for ${SERVICE}"
        }
    }
}
```

---

## Paso 14: Ejecutar el Pipeline

1. En Dashboard, click en `ecommerce-dev-pipeline`

2. Click **"Build with Parameters"** (menú izquierdo)

3. Seleccionar SERVICE: `user-service`

4. Click **"Build"**

5. Observar progreso en "Build History" (abajo izquierda)

6. Click en el número de build (ej: #1)

7. Click **"Console Output"** para ver logs en tiempo real

**Screenshots a capturar**:
- Pantalla "Build with Parameters"
- Pipeline ejecutando (vista Stage View)
- Console Output mostrando progreso
- Pipeline completado exitosamente (checkmarks verdes)

---

## Paso 15: Ver Resultados del Pipeline

### En la Vista del Pipeline:

- **Stage View**: Muestra cada stage con tiempo de ejecución
- Checkmarks verdes = Éxito
- X roja = Fallo

### En Console Output:

Deberías ver:
```
Started by user Jenkins Admin
Running in Durability level: MAX_SURVIVABILITY
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/ecommerce-dev-pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Build)
[Pipeline] dir
Running in /workspace/user-service
[Pipeline] sh
+ echo Building user-service with Java 11 (Docker)...
Building user-service with Java 11 (Docker)...
+ docker run --rm -v ...
[INFO] Scanning for projects...
[INFO] Building user-service 0.1.0
...
[INFO] BUILD SUCCESS
...
[Pipeline] } // stage
[Pipeline] stage
[Pipeline] { (Unit Tests)
...
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
...
[INFO] BUILD SUCCESS
...
[Pipeline] stage
[Pipeline] { (Build Docker Image)
...
Successfully built a1b2c3d4e5f6
Successfully tagged selimhorri/user-service-ecommerce-boot:dev-1
...
[Pipeline] stage
[Pipeline] { (Push to Docker Hub)
...
The push refers to repository [docker.io/selimhorri/user-service-ecommerce-boot]
dev-1: digest: sha256:... size: 1234
...
[Pipeline] End of Pipeline
Finished: SUCCESS
```

**Screenshots a capturar**:
- Console Output completo
- Sección "BUILD SUCCESS" de Maven
- Sección "Successfully tagged" de Docker
- "Finished: SUCCESS" al final

---

## Paso 16: Ver Artefactos y Resultados de Pruebas

1. En la página del build, click **"Test Result"** (si hay pruebas)

2. Verás:
   - Total tests ejecutados
   - Passed/Failed/Skipped
   - Duración de cada test

**Screenshot a capturar**: Resultados de pruebas unitarias

---

## Paso 17: Ejecutar para Múltiples Servicios

Repetir Paso 14 para cada servicio:
- `product-service`
- `order-service`
- `api-gateway`
- `service-discovery`

**Tip**: Puedes ejecutar varios builds en paralelo, Jenkins los encolará.

**Screenshot a capturar**: Build History mostrando múltiples builds exitosos

---

## Troubleshooting

### Problema 1: "Cannot connect to Docker daemon"

**Causa**: Jenkins no tiene acceso al Docker socket

**Solución**:
```bash
# Opción A: Reinstalar Jenkins con permisos correctos
docker stop jenkins-local
docker rm jenkins-local

# Dar permisos al socket
sudo chmod 666 /var/run/docker.sock

# Reiniciar Jenkins
docker run -d \
  --name jenkins-local \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add $(stat -c '%g' /var/run/docker.sock) \
  jenkins/jenkins:2.426.1-lts

# Opción B: Instalar Docker dentro de Jenkins
docker exec -u root jenkins-local apt-get update
docker exec -u root jenkins-local apt-get install -y docker.io
```

### Problema 2: "Permission denied" al ejecutar Maven

**Causa**: Problema de permisos en volúmenes

**Solución**:
```bash
# Dar permisos al directorio del proyecto
chmod -R 755 /home/osgomez/Code/icesi_codes/8vo_semestre/ingesoft_V/taller_2/ecommerce-microservice-backend-app
```

### Problema 3: "Failed to connect to repository"

**Causa**: Usando SCM Git con path local

**Solución**: Usar "Pipeline script" en lugar de "Pipeline script from SCM" y pegar el contenido del Jenkinsfile directamente.

### Problema 4: Maven descarga lento

**Causa**: Primera ejecución descarga todas las dependencias

**Solución**: Esperar. Ejecuciones subsecuentes serán más rápidas gracias al caché de Maven.

### Problema 5: "docker push" falla con "unauthorized"

**Causa**: Credenciales de Docker Hub incorrectas

**Solución**:
1. Verificar credenciales en Manage Jenkins → Manage Credentials
2. Intentar login manual:
   ```bash
   docker login
   # Ingresar usuario y password
   ```
3. Recrear credenciales en Jenkins con ID exacto: `dockerhub-credentials`

### Problema 6: "No tests found"

**Causa**: Las pruebas aún no están implementadas en ese servicio

**Solución**: Normal, el pipeline continuará. El reporte mostrará "0 tests".

### Problema 7: Puerto 8080 ya en uso

**Causa**: Otro servicio usando el puerto

**Solución**:
```bash
# Ver qué usa el puerto
sudo ss -tulpn | grep :8080

# Detener el servicio o cambiar puerto de Jenkins
docker run -d \
  --name jenkins-local \
  -p 8081:8080 \  # Cambiar a 8081
  ...

# Luego acceder en http://localhost:8081
```

---

## Validación Final

Al terminar deberías tener:

✅ **Infraestructura**:
- [ ] Jenkins corriendo en http://localhost:8080
- [ ] Usuario admin creado
- [ ] Plugins instalados
- [ ] Credenciales Docker Hub configuradas

✅ **Pipeline**:
- [ ] Job `ecommerce-dev-pipeline` creado
- [ ] Parámetro SERVICE configurado
- [ ] Jenkinsfile cargado

✅ **Ejecuciones**:
- [ ] Al menos 1 build exitoso de user-service
- [ ] Build muestra: Build → Tests → Docker Build → Push → Deploy
- [ ] Imagen Docker subida a Docker Hub

✅ **Screenshots Capturados**:
- [ ] Unlock Jenkins con contraseña
- [ ] Instalación de plugins
- [ ] Dashboard principal
- [ ] Configuración de credenciales
- [ ] Configuración de pipeline
- [ ] Build with Parameters
- [ ] Stage View con stages exitosos
- [ ] Console Output completo
- [ ] Test Results
- [ ] Build History con múltiples builds

---

## Comandos Útiles

### Ver logs de Jenkins en tiempo real:
```bash
docker logs -f jenkins-local
```

### Acceder al shell de Jenkins:
```bash
docker exec -it jenkins-local bash
```

### Ver espacio usado por Jenkins:
```bash
docker system df -v | grep jenkins
```

### Backup de configuración Jenkins:
```bash
docker exec jenkins-local tar czf /tmp/jenkins-backup.tar.gz -C /var/jenkins_home .
docker cp jenkins-local:/tmp/jenkins-backup.tar.gz ./jenkins-backup.tar.gz
```

### Detener Jenkins:
```bash
docker stop jenkins-local
```

### Reiniciar Jenkins:
```bash
docker restart jenkins-local
```

### Eliminar Jenkins completamente:
```bash
docker stop jenkins-local
docker rm jenkins-local
docker volume rm jenkins_home
```

---

## Resumen de Tiempo

| Paso | Actividad | Tiempo |
|------|-----------|--------|
| 1-4 | Instalación Jenkins | 5 min |
| 5-8 | Setup inicial | 15 min |
| 9-10 | Configuración credenciales | 5 min |
| 11-13 | Crear pipeline | 10 min |
| 14-16 | Primera ejecución | 10 min |
| 17 | Ejecuciones adicionales | 5 min/servicio |
| **Total** | | **45-60 min** |

---

## Próximos Pasos

Después de completar esta guía:

1. Capturar todos los screenshots listados
2. Organizar screenshots en carpeta `docs/screenshots/jenkins/`
3. Documentar en el reporte del taller:
   - Configuración realizada
   - Resultados obtenidos
   - Análisis de las pruebas
4. Opcional: Configurar pipelines STAGE y MASTER siguiendo la misma metodología

---

## Referencias

- Documentación oficial Jenkins: https://www.jenkins.io/doc/
- Jenkins Pipeline syntax: https://www.jenkins.io/doc/book/pipeline/syntax/
- Docker Hub: https://hub.docker.com/
- Tutorial Jenkins + Docker: https://www.jenkins.io/doc/book/installing/docker/
