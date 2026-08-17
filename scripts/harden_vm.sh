#!/bin/bash
# Script de hardening básico para la VM de PostgreSQL
# Asumiendo Ubuntu 22.04

set -euo pipefail

echo "=== Aplicando hardening básico de seguridad ==="

# 1. Actualizar sistema
apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y

# 2. Configurar UFW (Uncomplicated Firewall)
if ! command -v ufw &> /dev/null; then
    apt-get install -y ufw
fi

# Denegar todo por defecto
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH (puerto 22) - ajustar si se usa otro puerto
ufw allow 22/tcp comment 'SSH'

# Permitir PostgreSQL (puerto 5432) solo desde rangos de confianza
# En producción, reemplazar con el rango de la App Service o VNet de Azure
# Por ahora, permitir desde cualquier IP para facilitar pruebas (NO EN PRODUCCIÓN)
ufw allow 5432/tcp comment 'PostgreSQL - AJUSTAR EN PRODUCCIÓN'

# Habilitar UFW
ufw --force enable

echo "UFW configurado y habilitado:"
ufw status verbose

# 3. Configurar fail2ban para SSH (opcional pero recomendado)
if ! command -v fail2ban &> /dev/null; then
    apt-get install -y fail2ban
fi

# Configuración básica de fail2ban para SSH
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl restart fail2ban
systemctl enable fail2ban

echo "fail2ban instalado y configurado para SSH."

# 4. Deshabilitar login root por SSH (si no se ha hecho ya)
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    # Asegurar que PermitRootLogin esté establecido a no
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    # Reiniciar SSH para aplicar cambios
    systemctl restart sshd
    echo "SSH configurado: deshabilitado login root."
else
    echo "Advertencia: No se encontró $SSHD_CONFIG"
fi

# 5. Actualizar motd (mensaje del día) con advertencia
cat > /etc/motd <<EOF
Advertencia: Sistema bajo monitoreo.
El acceso no autorizado está prohibido y será registrado.
Todas las actividades pueden ser monitorizadas.
EOF

echo "=== Hardening básico completado ==="
echo "Resumen de acciones:"
echo "  - Sistema actualizado"
echo "  - UFW configurado (reglas: SSH entrada, PostgreSQL entrada, salida permitida)"
echo "  - fail2ban instalado y configurado para SSH"
echo "  - Login root por SSH deshabilitado"
echo "  - Motd actualizado con advertencia"
echo ""
echo "Próximos pasos recomendados:"
echo "  1. Cambiar el puerto SSH por defecto (opcional)"
echo "  2. Implementar monitoreo de logs (ej: logwatch o azure monitor)"
echo "  3. Considerar usar claves SSH y deshabilitar autenticación por contraseña"
echo "  4. Para producción, restringir el acceso a PostgreSQL (5432) a IPs específicas"
echo "  5. Habilitar cifrado de disco si la plataforma lo permite (Azure Disk Encryption)"
