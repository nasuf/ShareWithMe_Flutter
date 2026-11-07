#!/usr/bin/env bash
# 交互式选择设备并安装运行 ShareWithMe。
#
# 用法:
#   scripts/install.sh                 # 列出设备，选择后以 release 模式安装并运行
#   scripts/install.sh --debug         # 使用 debug 模式（支持热重载）
#   scripts/install.sh --profile       # 使用 profile 模式
#   scripts/install.sh -d <device_id>  # 跳过选择，直接指定设备
#   scripts/install.sh -- <额外 flutter run 参数>
#
# 可选环境变量（设置后会通过 --dart-define 传入应用）:
#   SHARE_WITH_ME_BACKEND_URL   后端地址
#   SHARE_WITH_ME_API_TOKEN     后端 API token
set -euo pipefail

cd "$(dirname "$0")/.."

mode="release"
device_id=""
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug|--profile|--release) mode="${1#--}"; shift ;;
    -d|--device) device_id="${2:?缺少设备 ID}"; shift 2 ;;
    --) shift; extra_args=("$@"); break ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

command -v flutter >/dev/null || { echo "未找到 flutter，请先加入 PATH" >&2; exit 1; }
command -v jq >/dev/null || { echo "需要 jq: brew install jq" >&2; exit 1; }

if [[ -z "$device_id" ]]; then
  echo "正在扫描设备（含无线设备）..."
  # --machine 输出 JSON；stderr 里的提示信息丢弃。
  json="$(flutter devices --machine 2>/dev/null)"

  ids=(); labels=()
  while IFS=$'\t' read -r id name platform emulator; do
    kind="真机"; [[ "$emulator" == "true" ]] && kind="模拟器"
    ids+=("$id"); labels+=("$name  [$platform · $kind]  ($id)")
  done < <(jq -r '.[] | [.id, .name, .targetPlatform, (.emulator|tostring)] | @tsv' <<<"$json")

  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "没有找到可用设备。请连接手机或启动模拟器（flutter emulators --launch <id>）。" >&2
    exit 1
  fi

  echo
  echo "可用设备:"
  for i in "${!ids[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "${labels[$i]}"
  done
  echo

  while true; do
    read -r -p "选择设备编号 [1-${#ids[@]}]（q 退出）: " choice
    [[ "$choice" == "q" ]] && exit 0
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#ids[@]} )); then
      device_id="${ids[$((choice - 1))]}"
      echo "已选择: ${labels[$((choice - 1))]}"
      break
    fi
    echo "无效输入，请重试。"
  done
fi

defines=()
[[ -n "${SHARE_WITH_ME_BACKEND_URL:-}" ]] && defines+=("--dart-define=SHARE_WITH_ME_BACKEND_URL=$SHARE_WITH_ME_BACKEND_URL")
[[ -n "${SHARE_WITH_ME_API_TOKEN:-}" ]] && defines+=("--dart-define=SHARE_WITH_ME_API_TOKEN=$SHARE_WITH_ME_API_TOKEN")

echo "以 $mode 模式构建并安装到 $device_id ..."
exec flutter run "--$mode" -d "$device_id" ${defines[@]+"${defines[@]}"} ${extra_args[@]+"${extra_args[@]}"}
