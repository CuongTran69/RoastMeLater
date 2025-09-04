#!/bin/bash

echo "Fixing CocoaPods permissions..."

# Fix permissions for Pods directory
if [ -d "Pods" ]; then
    find Pods -type d -exec chmod 755 {} \;
    find Pods -type f -exec chmod 644 {} \;
    find Pods -name "*.sh" -exec chmod 755 {} \;
    find Pods -name "*.framework" -exec chmod -R 755 {} \;
fi

# Fix permissions for RxCocoa specifically
if [ -d "Pods/RxCocoa" ]; then
    chmod -R 755 Pods/RxCocoa
fi

# Fix permissions for build scripts
if [ -d "Pods/Target Support Files" ]; then
    find "Pods/Target Support Files" -name "*.sh" -exec chmod 755 {} \;
fi

echo "Permissions fixed!"
