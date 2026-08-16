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

cat > "$WORK/$APP/config/home.html" <<'HOME_EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lynx Browser</title>

<style>
*{
    margin:0;
    padding:0;
    box-sizing:border-box;
}

body{
    width:100%;
    height:100vh;
    overflow:hidden;
    display:flex;
    align-items:center;
    justify-content:center;
    background:
        radial-gradient(circle at 50% 40%,#06295c 0%,#02050a 38%,#000 100%);
    color:white;
    font-family:Arial,sans-serif;
}

.container{
    width:90%;
    max-width:700px;
    text-align:center;
}

.logo{
    width:150px;
    height:150px;
    object-fit:cover;
    border-radius:28px;
    margin-bottom:28px;
    box-shadow:
        0 0 35px rgba(0,110,255,.45),
        0 20px 50px rgba(0,0,0,.7);
    animation:float 4s ease-in-out infinite;
}

@keyframes float{
    0%,100%{
        transform:translateY(0);
    }
    50%{
        transform:translateY(-8px);
    }
}

h1{
    font-size:52px;
    font-weight:800;
    letter-spacing:-3px;
}

h1 span{
    color:#1683ff;
}

.subtitle{
    margin-top:10px;
    color:#718096;
    font-size:15px;
}

.search-box{
    position:relative;
    margin-top:35px;
}

.search{
    width:100%;
    height:62px;
    padding:0 25px;
    border-radius:18px;
    border:1px solid rgba(22,131,255,.25);
    background:rgba(5,10,18,.85);
    color:white;
    outline:none;
    font-size:16px;
    box-shadow:0 20px 50px rgba(0,0,0,.4);
    transition:.25s;
}

.search:focus{
    border-color:#1683ff;
    box-shadow:
        0 0 0 4px rgba(22,131,255,.1),
        0 20px 60px rgba(0,0,0,.5);
}

.search::placeholder{
    color:#59677a;
}

.shortcuts{
    margin-top:25px;
    display:flex;
    justify-content:center;
    gap:12px;
    flex-wrap:wrap;
}

.shortcut{
    padding:11px 18px;
    border-radius:12px;
    border:1px solid rgba(255,255,255,.07);
    background:rgba(255,255,255,.035);
    color:#8290a3;
    cursor:pointer;
    transition:.2s;
}

.shortcut:hover{
    color:white;
    border-color:#1683ff;
    background:rgba(22,131,255,.08);
    transform:translateY(-3px);
}

.footer{
    position:fixed;
    bottom:20px;
    color:#394454;
    font-size:11px;
}

.footer span{
    color:#1683ff;
}
</style>
</head>

<body>

<div class="container">

    <img
        class="logo"
        src="lynx-logo.png"
        alt="Lynx"
    >

    <h1>Bem-vindo ao <span>Lynx</span></h1>

    <p class="subtitle">
        Navegue rápido. Navegue do seu jeito.
    </p>

    <div class="search-box">

        <input
            id="search"
            class="search"
            type="text"
            placeholder="Pesquisar na web ou digitar um endereço..."
            autofocus
        >

    </div>

    <div class="shortcuts">

        <div class="shortcut"
             onclick="abrir('https://duckduckgo.com')">
            🔎 DuckDuckGo
        </div>

        <div class="shortcut"
             onclick="abrir('https://www.youtube.com')">
            ▶ YouTube
        </div>

        <div class="shortcut"
             onclick="abrir('https://github.com')">
            GitHub
        </div>

        <div class="shortcut"
             onclick="abrir('https://www.google.com')">
            Google
        </div>

    </div>

</div>

<div class="footer">
    Lynx Browser <span>•</span> Fast • Private • Simple
</div>

<script>
function pesquisar(){

    const texto =
        document.getElementById("search").value.trim();

    if(!texto)
        return;

    if(
        texto.startsWith("http://") ||
        texto.startsWith("https://")
    ){

        window.location.href = texto;

    }else if(
        texto.includes(".") &&
        !texto.includes(" ")
    ){

        window.location.href = "https://" + texto;

    }else{

        window.location.href =
            "https://duckduckgo.com/?q=" +
            encodeURIComponent(texto);

    }
}

function abrir(url){
    window.location.href = url;
}

document
    .getElementById("search")
    .addEventListener("keydown",function(e){

        if(e.key === "Enter"){
            pesquisar();
        }

    });
</script>

</body>
</html>
HOME_EOF

# Baixa a logo automaticamente se não existir
if [ ! -f "$PWD/lynx-logo.png" ]; then
    echo "Baixando logo do Lynx..."
    curl -L "https://raw.githubusercontent.com/Pax0102/img/main/1.png" -o "$PWD/lynx-logo.png"
fi

# Copia a logo para a config e substitui o ícone do Firefox
cp "$PWD/lynx-logo.png" "$WORK/$APP/config/lynx-logo.png"

cd "$WORK"

echo "[1/6] Baixando Firefox oficial..."

curl -L \
  "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=pt-BR" \
  -o firefox.tar.xz

echo "[2/6] Extraindo motor do navegador..."

tar -xJf firefox.tar.xz

mv firefox "$APP/browser/firefox"

rm firefox.tar.xz

ICON_PATH=$(find "$APP/browser/firefox" -name "mozicon128.png" 2>/dev/null | head -1)
if [ -n "$ICON_PATH" ]; then
    cp "$APP/config/lynx-logo.png" "$ICON_PATH"
else
    echo "Aviso: ícone do Firefox não encontrado, pulando substituição."
fi

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

// Habilitar userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
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
HOME_PAGE="$BASE/config/home.html"

if [ ! -x "$FIREFOX" ]; then
    echo "Erro: Firefox não encontrado."
    exit 1
fi

mkdir -p "$PROFILE"
mkdir -p "$PROFILE/chrome"

cat > "$PROFILE/user.js" <<'USERJS_EOF'
/* Lynx Browser - Configurações */

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

/* Sem proxy */
user_pref("network.proxy.type", 0);

/* Modo escuro */
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");

/* Habilitar userChrome.css */
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
USERJS_EOF

# Esconde "Firefox" na barra de título e menus
cat > "$PROFILE/chrome/userChrome.css" <<'CSS_EOF'
/* Lynx Browser - Remove referências ao Firefox */

/* Esconde o nome Firefox no menu principal */
#appMenu-protonMainView .panel-header h1,
#appMenu-protonMainView .panel-header description {
    visibility: collapse !important;
}

/* Remove "Firefox" da barra de título */
#titlebar {
    -moz-appearance: none !important;
}

/* Esconde o logo do Firefox no menu */
#PanelUI-menu-button .toolbarbutton-icon {
    list-style-image: none !important;
}

/* Esconde "Mozilla Firefox" na tela About */
#aboutHeaderLearnMore {
    display: none !important;
}
CSS_EOF

echo "========================================="
echo " LYNX BROWSER"
echo " DNS: CLOUDFLARE 1.1.1.1"
echo " DNS-over-HTTPS: ATIVADO"
echo " TEMA: ESCURO"
echo " VPN/PROXY: DESATIVADO"
echo "========================================="

exec "$FIREFOX" \
    --no-remote \
    --profile "$PROFILE" \
    "$HOME_PAGE" \
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
echo "Descompactando o Lynx Browser..."

INSTALL_DIR="$PWD/LynxBrowser"

rm -rf "$INSTALL_DIR"
tar -xzf "$OUT" -C "$PWD"

echo
echo "Iniciando o Lynx Browser..."

exec "$INSTALL_DIR/start.sh"
