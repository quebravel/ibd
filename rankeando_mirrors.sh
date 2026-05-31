#!/usr/bin/env bash
# =============================================================================
#  rankeando_mirrors.sh — Rankeia e aplica os melhores mirrors do Arch Linux
#  Dependências: rankmirrors (pacman-contrib), curl, reflector (opcional)
#  feito com claude
# =============================================================================

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
#  CONFIGURAÇÕES
# ──────────────────────────────────────────────────────────────────────────────
readonly MIRRORLIST="/etc/pacman.d/mirrorlist"
readonly BACKUP="${MIRRORLIST}.bak.$(date +%Y%m%d_%H%M%S)"
readonly MIRRORLIST_URL="https://archlinux.org/mirrorlist/?country=BR&country=US&protocol=https&use_mirror_status=on"
readonly TEMP_FILE=$(mktemp /tmp/mirrorlist.XXXXXX)
readonly LOG_FILE="/tmp/rankeando_mirrors.log"
readonly TOP_N=10      # número de mirrors a testar
readonly TIMEOUT=5     # timeout por mirror (segundos)
readonly NUM_THREADS=5 # downloads paralelos no rankmirrors

# ──────────────────────────────────────────────────────────────────────────────
#  CORES
# ──────────────────────────────────────────────────────────────────────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ──────────────────────────────────────────────────────────────────────────────
#  FUNÇÕES AUXILIARES
# ──────────────────────────────────────────────────────────────────────────────
msg() { echo -e "${CYAN}[•]${RESET} $*"; }
ok() { echo -e "${GREEN}[✔]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
err() { echo -e "${RED}[✘]${RESET} $*" >&2; }
titulo() {
  echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  $*${RESET}"
  echo -e "${CYAN}══════════════════════════════════════════${RESET}\n"
}

cleanup() {
  rm -f "$TEMP_FILE"
  msg "Arquivo temporário removido."
}
trap cleanup EXIT

checar_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Este script precisa ser executado como root."
    err "  Use: sudo $0"
    exit 1
  fi
}

checar_dependencias() {
  local deps=("rankmirrors" "curl")
  local faltando=()

  for dep in "${deps[@]}"; do
    command -v "$dep" &>/dev/null || faltando+=("$dep")
  done

  if [[ ${#faltando[@]} -gt 0 ]]; then
    err "Dependências ausentes: ${faltando[*]}"
    err "Instale com: pacman -S pacman-contrib curl"
    exit 1
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
#  BACKUP
# ──────────────────────────────────────────────────────────────────────────────
fazer_backup() {
  if [[ -f "$MIRRORLIST" ]]; then
    cp "$MIRRORLIST" "$BACKUP"
    ok "Backup salvo em: $BACKUP"
  else
    warn "Nenhum mirrorlist existente para fazer backup."
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
#  BAIXAR MIRRORLIST ATUALIZADO
# ──────────────────────────────────────────────────────────────────────────────
baixar_mirrorlist() {
  titulo "Baixando mirrorlist atualizado"
  msg "Fonte: $MIRRORLIST_URL"

  if ! curl -fsSL --connect-timeout 10 --max-time 30 \
    -o "$TEMP_FILE" "$MIRRORLIST_URL"; then
    err "Falha ao baixar o mirrorlist. Verifique sua conexão."
    exit 1
  fi

  # Descomentar todos os mirrors (rankmirrors precisa de linhas ativas)
  sed -i 's/^#Server/Server/' "$TEMP_FILE"

  local total
  total=$(grep -c '^Server' "$TEMP_FILE" || true)
  ok "Encontrados $total mirrors para testar."
}

# ──────────────────────────────────────────────────────────────────────────────
#  RANKEAR COM rankmirrors
# ──────────────────────────────────────────────────────────────────────────────
rankear_mirrors() {
  titulo "Rankeando os ${TOP_N} mirrors mais rápidos"
  msg "Isso pode levar alguns minutos..."
  msg "Timeout por mirror: ${TIMEOUT}s | Threads: ${NUM_THREADS}"
  echo ""

  local ranked_file
  ranked_file=$(mktemp /tmp/ranked.XXXXXX)

  # Cabeçalho do mirrorlist final
  {
    echo "################################################################################"
    echo "# Arch Linux mirrorlist gerado por rankeando_mirrors.sh"
    echo "# Data: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "# Top ${TOP_N} mirrors (por latência) — ordenados do mais rápido ao mais lento"
    echo "################################################################################"
    echo ""
  } >"$ranked_file"

  # Executa rankmirrors com barra de progresso simples
  rankmirrors -n "$TOP_N" -t "$TIMEOUT" -p "$NUM_THREADS" "$TEMP_FILE" \
    2> >(grep -v '^$' | while IFS= read -r line; do
      echo -e "${YELLOW}  ${line}${RESET}" >&2
    done) |
    tee -a "$ranked_file" |
    grep '^Server' |
    while IFS= read -r server; do
      url="${server#Server = }"
      echo -e "  ${GREEN}✔${RESET} $url"
    done

  # Log completo
  cp "$ranked_file" "$LOG_FILE"

  # Aplicar mirrorlist
  cp "$ranked_file" "$MIRRORLIST"
  rm -f "$ranked_file"

  ok "Mirrorlist aplicado em: $MIRRORLIST"
}

# ──────────────────────────────────────────────────────────────────────────────
#  EXIBIR RESULTADO FINAL
# ──────────────────────────────────────────────────────────────────────────────
exibir_resultado() {
  titulo "Mirrorlist final"
  grep '^Server' "$MIRRORLIST" | nl -ba |
    awk '{printf "  \033[1;32m%2d.\033[0m %s\n", $1, $3}'
  echo ""
  ok "Log completo salvo em: $LOG_FILE"
}

# ──────────────────────────────────────────────────────────────────────────────
#  ATUALIZAR BASE DE DADOS DO PACMAN (opcional)
# ──────────────────────────────────────────────────────────────────────────────
atualizar_pacman() {
  echo ""
  read -rp "$(echo -e "${YELLOW}[?]${RESET} Atualizar a base de dados do pacman agora? [S/n]: ")" resp
  resp="${resp,,}" # lowercase
  if [[ "$resp" =~ ^(s|sim|yes|y|)$ ]]; then
    msg "Executando: pacman -Syy"
    pacman -Syy && ok "Base de dados atualizada com sucesso!"
  else
    warn "Atualização ignorada. Execute manualmente: sudo pacman -Syy"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
#  MAIN
# ──────────────────────────────────────────────────────────────────────────────
main() {
  titulo "rankeando_mirrors.sh"
  msg "Testando mirrors do Arch Linux com rankmirrors..."
  echo ""

  checar_root
  checar_dependencias
  fazer_backup
  baixar_mirrorlist
  rankear_mirrors
  exibir_resultado
  atualizar_pacman

  echo ""
  ok "Concluído! Seus mirrors estão otimizados."
}

main "$@"
