#!/bin/bash

set -e

echo "=========================================="
echo "Instalando Java 11 en Fedora"
echo "=========================================="

# Instalar Java 11
echo "Instalando OpenJDK 11..."
sudo dnf install -y java-11-openjdk java-11-openjdk-devel

# Esperar a que se complete la instalacion
sleep 2

# Buscar la ruta real de Java 11
echo ""
echo "Buscando ruta de instalacion..."
JAVA11_PATH=$(ls -d /usr/lib/jvm/java-11-openjdk-* 2>/dev/null | head -1)

if [ -z "$JAVA11_PATH" ]; then
    echo "ERROR: No se encontro Java 11 instalado"
    echo "Intentando buscar en otras ubicaciones..."
    find /usr/lib/jvm -name "*java-11*" -type d
    exit 1
fi

echo "Java 11 encontrado en: $JAVA11_PATH"

# Configurar alternatives
echo ""
echo "Configurando Java 11 como version por defecto..."
sudo alternatives --set java ${JAVA11_PATH}/bin/java
sudo alternatives --set javac ${JAVA11_PATH}/bin/javac

# Verificar
echo ""
echo "=========================================="
echo "Verificacion:"
echo "=========================================="
java -version
javac -version

# Crear archivo de entorno para el proyecto
echo ""
echo "Creando archivo .envrc para el proyecto..."
cat > /home/osgomez/Code/icesi_codes/8vo_semestre/ingesoft_V/taller_2/ecommerce-microservice-backend-app/.envrc << EOF
# Java 11 para este proyecto
export JAVA_HOME=${JAVA11_PATH}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

echo ""
echo "=========================================="
echo "Instalacion completada!"
echo "=========================================="
echo ""
echo "Java 11 instalado en: $JAVA11_PATH"
echo ""
echo "Para usar Java 11 en tu sesion actual:"
echo "  source .envrc"
echo ""
echo "Luego compila con:"
echo "  ./mvnw clean package -DskipTests"
echo ""
