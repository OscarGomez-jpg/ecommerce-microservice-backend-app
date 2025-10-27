#!/bin/bash

# Script para optimizar los manifiestos de Kubernetes

OPTIMIZATION_VARS='        - name: SPRING_JPA_SHOW_SQL
          value: "false"
        - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK
          value: "WARN"
        - name: LOGGING_LEVEL_ORG_HIBERNATE
          value: "WARN"
        - name: SPRING_MAIN_LAZY_INITIALIZATION
          value: "true"
        - name: JAVA_TOOL_OPTIONS
          value: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+TieredCompilation -XX:TieredStopAtLevel=1"'

for service in product-service order-service; do
  file="k8s-minikube/$(ls k8s-minikube/ | grep -i ${service})"

  if [ -f "$file" ]; then
    echo "Optimizando $file..."

    # Agregar variables de optimización antes de la línea de resources
    sed -i '/^        resources:/i\        - name: SPRING_JPA_SHOW_SQL\n          value: "false"\n        - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK\n          value: "WARN"\n        - name: LOGGING_LEVEL_ORG_HIBERNATE\n          value: "WARN"\n        - name: SPRING_MAIN_LAZY_INITIALIZATION\n          value: "true"\n        - name: JAVA_TOOL_OPTIONS\n          value: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+TieredCompilation -XX:TieredStopAtLevel=1"' "$file"

    # Actualizar readinessProbe
    sed -i 's/initialDelaySeconds: 240/initialDelaySeconds: 120/' "$file"
    sed -i 's/failureThreshold: 30/failureThreshold: 60/' "$file"
    sed -i '/periodSeconds: 10/a\          timeoutSeconds: 5' "$file"

    echo "✓ $file optimizado"
  fi
done

echo ""
echo "Optimización completada!"
