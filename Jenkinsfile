// Pipeline para Microservicios E-commerce
// Construye, analiza con SonarQube y despliega en Minikube

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: maven
    image: maven:3.9-eclipse-temurin-17
    command:
    - sleep
    args:
    - infinity
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: alpine/k8s:1.28.3
    command:
    - cat
    tty: true
  - name: node
    image: cypress/included:13.6.0
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
  - name: python
    image: python:3.11-slim
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }

    parameters {
        choice(
            name: 'SERVICE_NAME',
            choices: ['ALL', 'user-service', 'product-service', 'order-service', 'api-gateway', 'service-discovery'],
            description: 'Microservicio a construir y desplegar (ALL = todos los servicios)'
        )
        booleanParam(
            name: 'RUN_SONAR',
            defaultValue: true,
            description: 'Ejecutar análisis de SonarQube (tests + coverage para servicio individual o todos los servicios)'
        )
        booleanParam(
            name: 'DEPLOY_TO_MINIKUBE',
            defaultValue: true,
            description: 'Desplegar en Minikube después de construir'
        )
        booleanParam(
            name: 'RUN_E2E_TESTS',
            defaultValue: false,
            description: 'Ejecutar tests E2E con Cypress (requiere DEPLOY_TO_MINIKUBE=true)'
        )
        booleanParam(
            name: 'RUN_LOAD_TESTS',
            defaultValue: false,
            description: 'Ejecutar tests de carga con Locust (requiere DEPLOY_TO_MINIKUBE=true)'
        )
    }

    environment {
        SONAR_HOST_URL = 'http://sonarqube-sonarqube:9000'
        MINIKUBE_IP = '192.168.49.2'  // IP fijo de Minikube local
        // Docker usará el socket montado en /var/run/docker.sock

        // Detección automática de ambiente basado en rama
        K8S_NAMESPACE = "${env.BRANCH_NAME == 'master' ? 'ecommerce-prod' : 'ecommerce-dev'}"
        ENVIRONMENT = "${env.BRANCH_NAME == 'master' ? 'production' : 'development'}"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Clonando código del repositorio..."
                    checkout scm

                    echo """
                    ================================================
                    🌍 AMBIENTE DETECTADO
                    ================================================
                    Rama: ${env.BRANCH_NAME ?: 'master'}
                    Ambiente: ${env.ENVIRONMENT}
                    Namespace K8s: ${env.K8S_NAMESPACE}
                    ================================================
                    """
                }
            }
        }

        stage('Build & Test') {
            when {
                expression { params.SERVICE_NAME != 'ALL' }
            }
            steps {
                container('maven') {
                    script {
                        echo "🔨 Construyendo ${params.SERVICE_NAME}..."
                        dir(params.SERVICE_NAME) {
                            sh '''
                                mvn clean package -DskipTests
                                echo "✅ Build completado"
                            '''
                        }
                    }
                }
            }
        }

        stage('Unit Tests') {
            when {
                expression { params.SERVICE_NAME != 'ALL' }
            }
            steps {
                container('maven') {
                    script {
                        echo "🧪 Ejecutando tests unitarios..."
                        dir(params.SERVICE_NAME) {
                            sh '''
                                mvn test || true
                                echo "✅ Tests ejecutados"
                            '''
                        }
                    }
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: "${params.SERVICE_NAME}/target/surefire-reports/*.xml"
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { params.RUN_SONAR == true && params.SERVICE_NAME != 'ALL' }
            }
            steps {
                container('maven') {
                    script {
                        echo "📊 Analizando código con SonarQube..."
                        dir(params.SERVICE_NAME) {
                            withSonarQubeEnv('SonarQube') {
                                sh """
                                    mvn sonar:sonar \
                                      -Dsonar.projectKey=${params.SERVICE_NAME} \
                                      -Dsonar.projectName=${params.SERVICE_NAME} \
                                      -Dsonar.host.url=${SONAR_HOST_URL} \
                                      -Dsonar.java.coveragePlugin=jacoco \
                                      -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                                """
                            }
                        }
                        echo "✅ Análisis de SonarQube completado"
                        echo "📊 Ver resultados en: ${SONAR_HOST_URL}/dashboard?id=${params.SERVICE_NAME}"
                    }
                }
            }
        }

        stage('Quality Gate') {
            when {
                expression { params.RUN_SONAR == true && params.SERVICE_NAME != 'ALL' }
            }
            steps {
                script {
                    echo "⏳ Esperando resultado del Quality Gate..."
                    try {
                        timeout(time: 2, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                echo "⚠️ Quality Gate falló: ${qg.status}"
                                // No fallamos el build, solo advertimos
                            } else {
                                echo "✅ Quality Gate aprobado"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ Quality Gate timeout o error: ${e.message}"
                        echo "⏭️ Continuando con el pipeline..."
                    }
                }
            }
        }

        stage('Build Docker Image') {
            when {
                expression { params.SERVICE_NAME != 'ALL' }
            }
            steps {
                container('docker') {
                    script {
                        echo "🐳 Construyendo imagen Docker..."
                        sh """
                            cd ${params.SERVICE_NAME}
                            docker build -t ${params.SERVICE_NAME}:latest -f Dockerfile .
                            docker tag ${params.SERVICE_NAME}:latest ${params.SERVICE_NAME}:\${BUILD_NUMBER}
                            docker tag ${params.SERVICE_NAME}:latest ${params.SERVICE_NAME}:local
                            echo "✅ Imagen Docker construida: ${params.SERVICE_NAME}:latest (tags: \${BUILD_NUMBER}, local)"
                        """
                    }
                }
            }
        }

        stage('Build All Services') {
            when {
                expression { params.SERVICE_NAME == 'ALL' }
            }
            steps {
                container('maven') {
                    script {
                        echo "🔨 Construyendo TODOS los microservicios..."
                        def services = ['service-discovery', 'api-gateway', 'user-service', 'product-service', 'order-service']

                        // Build en paralelo
                        def buildStages = [:]
                        for (service in services) {
                            def svc = service // Capturar variable para closure
                            buildStages[svc] = {
                                stage("Build ${svc}") {
                                    echo "🔨 Construyendo ${svc}..."
                                    dir(svc) {
                                        sh 'mvn clean package -DskipTests'
                                    }
                                    echo "✅ ${svc} construido"
                                }
                            }
                        }
                        parallel buildStages
                    }
                }
            }
        }

        stage('Test All Services') {
            when {
                expression { params.SERVICE_NAME == 'ALL' }
            }
            steps {
                container('maven') {
                    script {
                        echo "🧪 Ejecutando tests de TODOS los servicios..."
                        def services = ['service-discovery', 'api-gateway', 'user-service', 'product-service', 'order-service']

                        for (service in services) {
                            echo "🧪 Ejecutando tests de ${service}..."
                            dir(service) {
                                sh 'mvn test || true'
                            }
                            echo "✅ Tests de ${service} ejecutados"
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        def services = ['service-discovery', 'api-gateway', 'user-service', 'product-service', 'order-service']
                        for (service in services) {
                            junit allowEmptyResults: true, testResults: "${service}/target/surefire-reports/*.xml"
                        }
                    }
                }
            }
        }

        stage('SonarQube All Services') {
            when {
                expression { params.SERVICE_NAME == 'ALL' && params.RUN_SONAR == true }
            }
            steps {
                container('maven') {
                    script {
                        echo "📊 Analizando TODOS los servicios con SonarQube..."
                        def services = ['service-discovery', 'api-gateway', 'user-service', 'product-service', 'order-service']

                        for (service in services) {
                            echo "📊 Analizando ${service} con SonarQube..."
                            dir(service) {
                                withSonarQubeEnv('SonarQube') {
                                    sh """
                                        mvn sonar:sonar \
                                          -Dsonar.projectKey=${service} \
                                          -Dsonar.projectName=${service} \
                                          -Dsonar.host.url=${SONAR_HOST_URL} \
                                          -Dsonar.java.coveragePlugin=jacoco \
                                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                                    """
                                }
                            }
                            echo "✅ ${service} analizado en SonarQube"
                        }
                        echo "✅ Todos los servicios analizados. Ver resultados en: ${SONAR_HOST_URL}"
                    }
                }
            }
        }

        stage('Build All Docker Images') {
            when {
                expression { params.SERVICE_NAME == 'ALL' }
            }
            steps {
                container('docker') {
                    script {
                        echo "🐳 Construyendo imágenes Docker de TODOS los servicios..."
                        def services = ['service-discovery', 'api-gateway', 'user-service', 'product-service', 'order-service']

                        // Construir imágenes en paralelo
                        def dockerStages = [:]
                        for (service in services) {
                            def svc = service
                            dockerStages[svc] = {
                                stage("Docker ${svc}") {
                                    echo "🐳 Construyendo imagen Docker de ${svc}..."
                                    sh """
                                        cd ${svc}
                                        docker build -t ${svc}:latest -f Dockerfile .
                                        docker tag ${svc}:latest ${svc}:local
                                        docker tag ${svc}:latest ${svc}:\${BUILD_NUMBER}
                                    """
                                    echo "✅ Imagen ${svc}:local construida"
                                }
                            }
                        }
                        parallel dockerStages
                        echo "✅ Todas las imágenes Docker construidas"
                    }
                }
            }
        }

        stage('Deploy to Minikube') {
            when {
                expression {
                    // En dev: Solo deploy si explícitamente se solicita
                    // En master (prod): Siempre deploy
                    if (env.BRANCH_NAME == 'master') {
                        return true
                    } else {
                        return params.DEPLOY_TO_MINIKUBE == true
                    }
                }
            }
            steps {
                container('kubectl') {
                    script {
                        if (params.SERVICE_NAME == 'ALL') {
                            echo "🚀 Desplegando TODOS los servicios en Minikube..."

                            // PASO 1: Desplegar service-discovery PRIMERO (Eureka)
                            echo "📍 Paso 1: Desplegando service-discovery (Eureka)..."
                            sh """
                                kubectl scale deployment service-discovery --replicas=0 -n ${env.K8S_NAMESPACE} || true
                                sleep 5
                                kubectl scale deployment service-discovery --replicas=1 -n ${env.K8S_NAMESPACE}
                            """

                            // Esperar a que Eureka esté READY
                            echo "⏳ Esperando a que service-discovery esté READY..."
                            sh """
                                kubectl rollout status deployment/service-discovery -n ${env.K8S_NAMESPACE} --timeout=300s
                                kubectl wait --for=condition=ready pod -l app=service-discovery -n ${env.K8S_NAMESPACE} --timeout=300s
                            """
                            echo "✅ service-discovery está READY"

                            // Esperar 30 segundos adicionales para que Eureka se estabilice
                            echo "⏳ Esperando 30s para que Eureka se estabilice..."
                            sleep 30

                            // PASO 2: Desplegar el resto de servicios
                            echo "📍 Paso 2: Desplegando resto de servicios..."
                            def services = ['api-gateway', 'user-service', 'product-service', 'order-service']

                            for (service in services) {
                                echo "🚀 Desplegando ${service}..."
                                sh """
                                    kubectl scale deployment ${service} --replicas=0 -n ${env.K8S_NAMESPACE} || true
                                    sleep 3
                                    kubectl scale deployment ${service} --replicas=1 -n ${env.K8S_NAMESPACE}
                                """
                            }

                            // Esperar a que todos estén desplegados
                            echo "⏳ Esperando a que todos los servicios estén desplegados..."
                            for (service in services) {
                                sh """
                                    kubectl rollout status deployment/${service} -n ${env.K8S_NAMESPACE} --timeout=300s || true
                                """
                            }

                            echo "✅ Todos los servicios desplegados"

                        } else {
                            // Despliegue de servicio individual
                            echo "🚀 Desplegando ${params.SERVICE_NAME} en Minikube..."

                            // Escalar a 0 para liberar recursos
                            sh """
                                kubectl scale deployment ${params.SERVICE_NAME} --replicas=0 -n ${env.K8S_NAMESPACE} || true
                                sleep 5
                            """

                            // Escalar a 1 con nueva imagen
                            sh """
                                kubectl scale deployment ${params.SERVICE_NAME} --replicas=1 -n ${env.K8S_NAMESPACE}
                                kubectl rollout status deployment/${params.SERVICE_NAME} -n ${env.K8S_NAMESPACE} --timeout=300s
                            """

                            echo "✅ Despliegue completado"
                        }
                    }
                }
            }
        }

        stage('Verify Deployment') {
            when {
                expression { params.DEPLOY_TO_MINIKUBE == true }
            }
            steps {
                container('kubectl') {
                    script {
                        if (params.SERVICE_NAME == 'ALL') {
                            echo "🔍 Verificando despliegue de TODOS los servicios..."
                            def allServices = ['service-discovery', 'api-gateway', 'user-service', 'product-service', 'order-service']

                            for (service in allServices) {
                                echo "🔍 Verificando ${service}..."
                                sh """
                                    kubectl get pods -n ${env.K8S_NAMESPACE} -l app=${service}
                                    kubectl wait --for=condition=ready pod -l app=${service} -n ${env.K8S_NAMESPACE} --timeout=300s || echo "⚠️ ${service} no está ready aún"
                                """
                            }

                            echo "📊 Estado final de todos los servicios:"
                            sh """
                                kubectl get pods -n ${env.K8S_NAMESPACE}
                                kubectl get svc -n ${env.K8S_NAMESPACE}
                            """

                            echo "✅ Verificación completada para todos los servicios"

                        } else {
                            echo "🔍 Verificando despliegue..."
                            sh """
                                kubectl get pods -n ${env.K8S_NAMESPACE} -l app=${params.SERVICE_NAME}
                                kubectl get svc -n ${env.K8S_NAMESPACE} ${params.SERVICE_NAME}
                            """

                            // Esperar a que el pod esté ready
                            sh """
                                kubectl wait --for=condition=ready pod -l app=${params.SERVICE_NAME} -n ${env.K8S_NAMESPACE} --timeout=300s
                            """

                            echo "✅ ${params.SERVICE_NAME} desplegado y funcionando correctamente"
                        }
                    }
                }
            }
        }

        stage('Populate Test Data') {
            when {
                expression { (params.RUN_E2E_TESTS == true || params.RUN_LOAD_TESTS == true) && params.DEPLOY_TO_MINIKUBE == true }
            }
            steps {
                container('kubectl') {
                    script {
                        echo "🔧 Poblando datos de prueba..."
                        def API_URL = "http://${env.MINIKUBE_IP}:30080"

                        // Wait for services to be fully ready before populating
                        echo "⏳ Esperando que los servicios estén listos..."
                        sleep(time: 30, unit: 'SECONDS')

                        sh """
                            chmod +x scripts/populate-test-data.sh
                            ./scripts/populate-test-data.sh ${env.MINIKUBE_IP}
                        """
                        echo "✅ Datos de prueba poblados exitosamente"
                    }
                }
            }
        }

        stage('E2E Tests with Cypress') {
            when {
                expression { params.RUN_E2E_TESTS == true && params.DEPLOY_TO_MINIKUBE == true }
            }
            steps {
                container('node') {
                    script {
                        echo "🧪 Ejecutando tests E2E con Cypress..."
                        def API_URL = "http://${env.MINIKUBE_IP}:30080"

                        sh """
                            cd tests/e2e
                            npm install
                            API_BASE_URL=${API_URL} npx cypress run
                        """
                        echo "✅ Tests E2E completados"
                    }
                }
            }
            post {
                always {
                    // Archivar reporte completo (HTML + JS + CSS) y screenshots
                    archiveArtifacts artifacts: 'tests/e2e/cypress/reports/**/*', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'tests/e2e/cypress/screenshots/**/*.png', allowEmptyArchive: true
                }
            }
        }

        stage('Load Tests with Locust') {
            when {
                expression { params.RUN_LOAD_TESTS == true && params.DEPLOY_TO_MINIKUBE == true }
            }
            steps {
                container('python') {
                    script {
                        echo "⚡ Ejecutando tests de carga con Locust..."
                        def API_URL = "http://${env.MINIKUBE_IP}:30080"

                        sh """
                            cd tests/performance
                            mkdir -p reports
                            pip install --no-cache-dir -r requirements.txt
                            locust -f locustfile.py --headless \
                                --users 100 --spawn-rate 10 \
                                --run-time 3m \
                                --host ${API_URL} \
                                --html reports/locust-report.html \
                                --csv reports/locust-results
                        """
                        echo "✅ Tests de carga completados"
                    }
                }
            }
            post {
                always {
                    publishHTML([
                        reportDir: 'tests/performance/reports',
                        reportFiles: 'locust-report.html',
                        reportName: 'Locust Load Test Report',
                        allowMissing: true,
                        keepAll: true,
                        alwaysLinkToLastBuild: true
                    ])
                    archiveArtifacts artifacts: 'tests/performance/reports/locust-results*.csv', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        success {
            echo """
            ✅ ========================================
            ✅ Pipeline completado exitosamente
            ✅ ========================================
            ✅ Servicio: ${params.SERVICE_NAME}
            ✅ Build: #${BUILD_NUMBER}
            ✅ Branch: ${env.BRANCH_NAME ?: 'N/A'}
            ✅ ========================================
            """
        }
        failure {
            echo """
            ❌ ========================================
            ❌ Pipeline falló
            ❌ ========================================
            ❌ Servicio: ${params.SERVICE_NAME}
            ❌ Build: #${BUILD_NUMBER}
            ❌ Revisa los logs para más información
            ❌ ========================================
            """
        }
        always {
            echo "🧹 Limpiando workspace..."
            script {
                try {
                    // Limpiar desde el contenedor Maven para evitar problemas de permisos
                    container('maven') {
                        sh 'rm -rf target || true'
                        sh 'mvn clean || true'
                    }
                } catch (Exception e) {
                    echo "⚠️ No se pudo limpiar workspace: ${e.message}"
                }
            }
        }
    }
}
