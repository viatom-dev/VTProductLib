#!/bin/bash
#
# sdk-mode.sh — 切换 Demo 消费 VTMProductLib 的方式。
#
#   ./sdk-mode.sh            查看当前模式
#   ./sdk-mode.sh release    从 CocoaPods trunk 拉二进制（默认，提交前切回这个）
#   ./sdk-mode.sh source     用本地源码，可在 SDK 内部下断点
#   ./sdk-mode.sh source ~/other/checkout
#                            源码模式但指向别处
#
# 模式只在 pod install 时生效，所以这个脚本就是「带上/不带环境变量跑一次
# pod install」。切换结果记录在 Pods/ 和 Podfile.lock 里，直到下次 pod install。
#
# ⚠️ 源码模式产生的 Podfile.lock 含本机绝对路径，不要提交。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

ENV_NAME="VTM_PRODUCT_SDK_SOURCE"
POD_NAME="VTMProductLib"
DEFAULT_SOURCE="$(cd "${SCRIPT_DIR}/.." && pwd)"

[ -f Podfile ] || { echo "error: 当前目录没有 Podfile：${SCRIPT_DIR}" >&2; exit 1; }

current_mode() {
  if [ ! -f Podfile.lock ]; then
    echo "未安装（还没跑过 pod install）"
    return
  fi

  # 源码模式的唯一可靠标志：EXTERNAL SOURCES 段里出现该 pod 的 :path
  local path_line
  path_line=$(awk '/^EXTERNAL SOURCES:/,/^SPEC CHECKSUMS:/' Podfile.lock \
              | grep -A2 "^  ${POD_NAME}:" | grep ':path:' | head -1 \
              | sed -e 's/.*:path: *//' -e 's/^"//' -e 's/"$//')

  if [ -n "${path_line}" ]; then
    echo "source  (${path_line})"
  else
    local v
    v=$(grep -E "^  - ${POD_NAME} \(" Podfile.lock | head -1 | sed -E 's/.*\(([^)]*)\).*/\1/')
    echo "release (${v:-版本未解析})"
  fi
}

case "${1:-}" in
  "")
    echo "当前模式: $(current_mode)"
    echo
    echo "切换: ./sdk-mode.sh release | ./sdk-mode.sh source [path]"
    ;;

  release)
    echo "==> 切到 release 模式（trunk 二进制）"
    unset "${ENV_NAME}"
    env -u "${ENV_NAME}" pod install
    echo
    echo "当前模式: $(current_mode)"
    echo "Podfile.lock 可以提交。"
    ;;

  source)
    SRC="${2:-${DEFAULT_SOURCE}}"
    SRC="$(cd "${SRC}" 2>/dev/null && pwd)" \
      || { echo "error: 路径不存在：${2:-${DEFAULT_SOURCE}}" >&2; exit 1; }
    [ -f "${SRC}/${POD_NAME}.podspec" ] \
      || { echo "error: ${SRC} 下没有 ${POD_NAME}.podspec" >&2; exit 1; }

    echo "==> 切到 source 模式：${SRC}"
    env "${ENV_NAME}=${SRC}" pod install
    echo
    echo "当前模式: $(current_mode)"
    echo "⚠️  这份 Podfile.lock 含本机绝对路径，不要提交。提交前先 ./sdk-mode.sh release"
    ;;

  -h|--help|help)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    ;;

  *)
    echo "error: 未知模式 '$1'（可用：release / source）" >&2
    exit 64
    ;;
esac
