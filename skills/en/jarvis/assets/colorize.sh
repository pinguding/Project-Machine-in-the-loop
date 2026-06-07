#!/usr/bin/env bash
# jarvis 시작 배너 컬러 생성: jarvis-banner.txt(플레인) → jarvis-banner.ansi(ANSI 컬러)
#
# 라인 단위 색 매핑 (JARVIS 아크 리액터 팔레트):
#   블록 글자(█) 또는 받침(╚) 포함 라인 → bright cyan (로고 본체)
#   구분선(─) 라인                      → dim cyan
#   그 외(영문 캡션 등)                 → dim 회색
#
# 박스 드로잉/블록 글리프는 멀티바이트(UTF-8)라 byte 기반 awk substr로는
# 글자 단위 색칠이 깨진다(macOS awk). 로고가 단색 블록이므로 라인 단위로 칠한다.
set -euo pipefail
cd "$(dirname "$0")"
awk '
{
  if(index($0,"█")>0||index($0,"╚")>0) col="\033[96m"; # 로고 본체(받침 포함) → bright cyan
  else if(index($0,"─")>0) col="\033[2;36m"; # 구분선 → dim cyan
  else col="\033[90m";                          # 캡션/배경 → dim gray
  print col $0 "\033[0m";
}' jarvis-banner.txt > jarvis-banner.ansi
echo "jarvis-banner.ansi regenerated ($(wc -l < jarvis-banner.ansi) lines, $(wc -c < jarvis-banner.ansi) bytes)."
