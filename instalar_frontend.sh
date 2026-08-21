#!/bin/bash
echo "1. Instalando dependencias de Linux..."
apt-get update && apt-get install -y git curl unzip xz-utils zip libglu1-mesa

echo "2. Descargando Flutter (Tomará 1-2 minutos)..."
if [ ! -d ".flutter_sdk" ]; then
    git clone https://github.com/flutter/flutter.git -b stable .flutter_sdk
else
    echo "Flutter ya estaba descargado."
fi

echo "3. Configurando variables de entorno..."
export PATH="$PATH:$(pwd)/.flutter_sdk/bin"
grep -qxF 'export PATH="$PATH:'$(pwd)'/.flutter_sdk/bin"' ~/.bashrc || echo 'export PATH="$PATH:'$(pwd)'/.flutter_sdk/bin"' >> ~/.bashrc

echo "4. Habilitando Flutter Web y creando proyecto..."
flutter config --enable-web

if [ ! -d "frontend" ]; then
    flutter create frontend
else
    echo "La carpeta frontend ya existe."
fi

echo "¡Entorno 100% listo! Escribe 'source ~/.bashrc' y presiona Enter para activar Flutter."