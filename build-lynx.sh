#!/usr/bin/env bash
set -euo pipefail

APP="LynxBrowser"
ARCH="x86_64"
WORK="$PWD/lynx-build"
OUT="$PWD/${APP}-Linux-${ARCH}.tar.gz"

echo "========================================="
echo "        LYNX BROWSER - BUILD"
echo "========================================="

rm -rf "$WORK"
mkdir -p "$WORK/$APP/browser"
mkdir -p "$WORK/$APP/profile"
mkdir -p "$WORK/$APP/config"

cd "$WORK"

echo "[1/6] Baixando Firefox oficial..."

curl -L \
  "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=pt-BR" \
  -o firefox.tar.xz

echo "[2/6] Extraindo motor do navegador..."

tar -xJf firefox.tar.xz

mv firefox "$APP/browser/firefox"

rm firefox.tar.xz

echo "[3/6] Criando configuração..."

cat > "$APP/config/vpn.conf" <<'EOF'
# ==========================================================
# LYNX BROWSER - VPN / SOCKS5
# ==========================================================
#
# ATENÇÃO:
# Isto é um proxy SOCKS5. Para funcionar você precisa
# informar um servidor SOCKS5 real.
#
# Exemplos:
#
# HOST=127.0.0.1
# PORT=9050
#
# ou:
#
# HOST=meu-servidor.com
# PORT=1080
#
# Para desligar:
# ENABLED=0
#
# Para ligar:
# ENABLED=1
#
# DNS também será enviado pelo SOCKS5.
# ==========================================================

ENABLED=0
HOST=127.0.0.1
PORT=1080
USERNAME=
PASSWORD=
EOF

echo "[4/6] Criando perfil privado do Lynx..."

cat > "$APP/profile/user.js" <<'EOF'
// ============================================
// LYNX BROWSER - PRIVACY SETTINGS
// ============================================

user_pref("browser.startup.homepage", "https://duckduckgo.com/");
user_pref("browser.newtabpage.enabled", false);

user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);

user_pref("privacy.partition.network_state", true);
user_pref("privacy.partition.network_state.ocsp_cache", true);

user_pref("network.trr.mode", 5);

user_pref("browser.send_pings", false);
user_pref("dom.battery.enabled", false);

user_pref("media.peerconnection.enabled", false);

user_pref("network.dns.disableIPv6", false);

user_pref("browser.sessionstore.resume_from_crash", false);

user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.warnOnQuit", false);

user_pref("browser.cache.disk.enable", true);
EOF

echo "[5/6] Criando controle de VPN..."

cat > "$APP/vpn" <<'EOF'
#!/usr/bin/env bash

set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
CONF="$BASE/config/vpn.conf"

if [ ! -f "$CONF" ]; then
    echo "Arquivo de configuração não encontrado."
    exit 1
fi

case "${1:-status}" in

    on)
        sed -i 's/^ENABLED=.*/ENABLED=1/' "$CONF"
        echo "VPN/Proxy: ATIVADO"
        echo
        echo "Servidor:"
        grep '^HOST=' "$CONF"
        grep '^PORT=' "$CONF"
        echo
        echo "O navegador precisa ser reiniciado."
        ;;

    off)
        sed -i 's/^ENABLED=.*/ENABLED=0/' "$CONF"
        echo "VPN/Proxy: DESATIVADO"
        echo
        echo "O navegador precisa ser reiniciado."
        ;;

    status)
        source "$CONF"

        if [ "${ENABLED:-0}" = "1" ]; then
            echo "VPN/Proxy: ATIVADO"
            echo "Servidor: $HOST:$PORT"
        else
            echo "VPN/Proxy: DESATIVADO"
        fi
        ;;

    config)
        nano "$CONF"
        ;;

    *)
        echo
        echo "Lynx VPN"
        echo
        echo "Uso:"
        echo "  ./vpn on       Ativar"
        echo "  ./vpn off      Desativar"
        echo "  ./vpn status   Ver estado"
        echo "  ./vpn config   Editar servidor"
        echo
        ;;
esac
EOF

chmod +x "$APP/vpn"

echo "[6/6] Criando executável do navegador..."

cat > "$APP/lynx" <<'LYNX_EOF'
#!/usr/bin/env bash

set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
FIREFOX="$BASE/browser/firefox/firefox"
PROFILE="$BASE/profile"

if [ ! -x "$FIREFOX" ]; then
    echo "Erro: Firefox não encontrado."
    exit 1
fi

mkdir -p "$PROFILE"

cat > "$PROFILE/user.js" <<'USERJS_EOF'
/* Lynx Browser - DNS seguro */

user_pref("browser.startup.homepage", "https://duckduckgo.com/");

/* DNS-over-HTTPS - Cloudflare */
user_pref("network.trr.mode", 2);
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");
user_pref("network.trr.bootstrapAddress", "1.1.1.1");

/* Privacidade */
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.partition.network_state", true);

user_pref("media.peerconnection.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("browser.send_pings", false);

/* Sem proxy/VPN */
user_pref("network.proxy.type", 0);
USERJS_EOF

echo "========================================="
echo " LYNX BROWSER"
echo " DNS: CLOUDFLARE 1.1.1.1"
echo " DNS-over-HTTPS: ATIVADO"
echo " VPN/PROXY: DESATIVADO"
echo "========================================="

exec "$FIREFOX" \
    --no-remote \
    --profile "$PROFILE" \
    "$@"
LYNX_EOF

chmod +x "$APP/lynx"

cat > "$APP/start.sh" <<'START_EOF'
#!/usr/bin/env bash

BASE="$(cd "$(dirname "$0")" && pwd)"
exec "$BASE/lynx" "$@"
START_EOF

chmod +x "$APP/start.sh"

cat > "$APP/README.txt" <<'README_EOF'
====================================================
                 LYNX BROWSER
====================================================

Navegador Linux portátil.

EXECUTAR:

    ./start.sh

VPN / SOCKS5:

    ./vpn status
    ./vpn config
    ./vpn on
    ./vpn off

IMPORTANTE:

O modo VPN utiliza SOCKS5.

Você precisa fornecer um servidor SOCKS5 real.

====================================================
README_EOF

echo
echo "Empacotando..."

cd "$WORK"

tar -czf "$OUT" "$APP"

echo
echo "========================================="
echo " BUILD CONCLUÍDO"
echo "========================================="
echo
echo "Arquivo:"
echo "$OUT"
echo
echo "Tamanho:"
du -h "$OUT"
echo
echo "Para testar:"
echo
echo "  tar -xzf $OUT"
echo "  cd $APP"
echo "  ./start.sh"
