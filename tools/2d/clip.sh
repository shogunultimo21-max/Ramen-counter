#!/bin/zsh
# 영상 → 게임용 그림 묶음: clip.sh 이름 영상주소   (예: clip.sh woman_wait https://...mp4)
# 결과: OUT/이름.jpg (색) + OUT/이름_mask.png (모양) + 반복 구간 정보
set -e
S=/private/tmp/claude-501/-Users-jun-Applications---/3cedcec4-fa1b-43c6-9a10-74653cf193bd/scratchpad
OUT=${OUT:-/Users/jun/Applications/작업/ramen-shop/img/cust2d}
VID=/Users/jun/Applications/작업/ramen-shop/previews/2d/video
name=$1; url=$2
mkdir -p $OUT $VID
[ -n "$url" ] && curl -sSfL -o $VID/$name.mp4 "$url"
rm -rf $S/f_$name $S/c_$name; mkdir -p $S/c_$name
$S/frames $VID/$name.mp4 $S/f_$name 12 512 >/dev/null
for f in $S/f_$name/f0*.png; do b=${f:t:r}; BGTOP=1 FIXED=1 $S/slice $f 1 1 $S/c_$name 384 $b >/dev/null; done
top=$(TOP=$TOP FLOOD=${FLOOD:-0} TOL=60 $S/untable $S/c_$name/f0*.png | awk "/band top/{print \$4}")
# 반복: 처음 10장 중 하나 ↔ 끝쪽 25장 중 가장 비슷한 장
read s e < <($S/fdiff $S/c_$name 61 | head -1 | awk '{print $4, $6}')
n=$((e - s))
$S/pack $S/c_$name $s $n 8 384 $OUT/$name 0.8 >/dev/null
echo "$name: 탁자선 $top/384, 시작 $s, ${n}장 → $(du -k $OUT/$name.jpg | cut -f1)KB + $(du -k $OUT/${name}_mask.png | cut -f1)KB"
