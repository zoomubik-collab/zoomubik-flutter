#!/bin/bash

echo "🧹 Limpiando build..."

# Limpiar Flutter
flutter clean

# Limpiar Pods
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# Limpiar build de Xcode
rm -rf ios/build
rm -rf build

echo "✅ Limpieza completada"
echo "Ahora ejecuta: flutter pub get && cd ios && pod install && cd .."
