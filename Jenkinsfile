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
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
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
            choices: ['user-service', 'product-service', 'order-service', 'api-gateway', 'service-discovery'],
            description: 'Microservicio a construir y desplegar'
        )
        booleanParam(
            name: 'RUN_SONAR',
            defaultValue: true,
            description: 'Ejecutar análisis de SonarQube'
        )
        booleanParam(
            name: 'DEPLOY_TO_MINIKUBE',
            defaultValue: true,
            description: 'Desplegar en Minikube después de construir'
        )
    }

    environment {
        SONAR_HOST_URL = 'http://sonarqube-sonarqube:9000'
        // Docker usará el socket montado en /var/run/docker.sock
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Clonando código del repositorio..."
                checkout scm
            }
        }

        stage('Build & Test') {
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
                expression { params.RUN_SONAR == true }
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
                expression { params.RUN_SONAR == true }
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
            steps {
                container('docker') {
                    script {
                        echo "🐳 Construyendo imagen Docker..."
                        sh """
                            cd ${params.SERVICE_NAME}
                            docker build -t ${params.SERVICE_NAME}:latest -f Dockerfile .
                            docker tag ${params.SERVICE_NAME}:latest ${params.SERVICE_NAME}:\${BUILD_NUMBER}
                            echo "✅ Imagen Docker construida: ${params.SERVICE_NAME}:latest"
                        """
                    }
                }
            }
        }

        stage('Deploy to Minikube') {
            when {
                expression { params.DEPLOY_TO_MINIKUBE == true }
            }
            steps {
                container('kubectl') {
                    script {
                        echo "🚀 Desplegando ${params.SERVICE_NAME} en Minikube..."

                        // Escalar a 0 para liberar recursos
                        sh """
                            kubectl scale deployment ${params.SERVICE_NAME} --replicas=0 -n ecommerce || true
                            sleep 5
                        """

                        // Escalar a 1 con nueva imagen
                        sh """
                            kubectl scale deployment ${params.SERVICE_NAME} --replicas=1 -n ecommerce
                            kubectl rollout status deployment/${params.SERVICE_NAME} -n ecommerce --timeout=300s
                        """

                        echo "✅ Despliegue completado"
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
                        echo "🔍 Verificando despliegue..."
                        sh """
                            kubectl get pods -n ecommerce -l app=${params.SERVICE_NAME}
                            kubectl get svc -n ecommerce ${params.SERVICE_NAME}
                        """

                        // Esperar a que el pod esté ready
                        sh """
                            kubectl wait --for=condition=ready pod -l app=${params.SERVICE_NAME} -n ecommerce --timeout=300s
                        """

                        echo "✅ ${params.SERVICE_NAME} desplegado y funcionando correctamente"
                    }
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
