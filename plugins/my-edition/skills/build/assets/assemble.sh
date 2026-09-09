#!/bin/sh
# Assemble a my-edition page: template + rail + content fragments, MathJax inlined.
# usage: assemble.sh <template> <title.txt> <rail.html> <mathjax.js|-> <out.html> <fragment.html>...
# Pass "-" for <mathjax.js> to keep the CDN tag (light version).
# Fragments may contain {{FILE:<path>}} which is replaced by that file's contents
# (used for base64 image data kept outside the fragment).
set -e
tpl="$1"; ttl="$2"; rail="$3"; mj="$4"; out="$5"
[ -n "$out" ] || { echo "usage: assemble.sh <template> <title.txt> <rail.html> <mathjax|-> <out> <fragment>..." >&2; exit 1; }
shift 5
[ -f "$tpl" ]  || { echo "no template: $tpl" >&2; exit 1; }
[ -f "$ttl" ]  || { echo "no title file: $ttl" >&2; exit 1; }
[ -f "$rail" ] || { echo "no rail: $rail" >&2; exit 1; }
[ "$mj" = "-" ] || [ -f "$mj" ] || { echo "no mathjax: $mj" >&2; exit 1; }
[ $# -ge 1 ]   || { echo "no content fragments given" >&2; exit 1; }
title=$(head -n 1 "$ttl")
case "$title" in
  *"'"*|*'<'*|*'>'*|*'&'*) echo "warning: title contains a special character; use a plain title" >&2 ;;
esac
# every fragment must exist; only the last one may carry the colophon
n=0
for f in "$@"; do
  n=$((n + 1))
  [ -f "$f" ] || { echo "no fragment: $f" >&2; exit 1; }
  if [ $n -lt $# ] && grep -q 'class="colophon"' "$f"; then
    echo "warning: $f is not the last fragment but contains a colophon; it will appear mid-book" >&2
  fi
done
# referenced external files must exist
grep -ho '{{FILE:[^}]*}}' "$@" 2>/dev/null | sed 's/{{FILE://; s/}}$//' | sort -u | while read -r p; do
  [ -f "$p" ] || echo "warning: referenced file not found: $p" >&2
done
frag=$(mktemp)
trap 'rm -f "$frag"' EXIT
for f in "$@"; do
  cat "$f" >> "$frag"
  echo "" >> "$frag"
done
TITLE="$title" awk -v RAIL="$rail" -v FRAG="$frag" -v MJ="$mj" -v Q='"' '
function expand(s,   p, q, path, data, line) {
  while ((p = index(s, "{{FILE:")) > 0) {
    q = index(substr(s, p), "}}")
    if (q == 0) break
    path = substr(s, p + 7, q - 8)
    data = ""
    while ((getline line < path) > 0) data = data line
    close(path)
    s = substr(s, 1, p - 1) data substr(s, p + q + 1)
  }
  return s
}
function subst(s,   t, p, tok) {
  tok = "{{BOOK_TITLE}}"; t = ENVIRON["TITLE"]
  while ((p = index(s, tok)) > 0) s = substr(s, 1, p - 1) t substr(s, p + length(tok))
  return s
}
function put(f,   line) { while ((getline line < f) > 0) print expand(line); close(f) }
index($0, "<!-- RAIL -->")    { put(RAIL); next }
index($0, "<!-- CONTENT -->") { put(FRAG); next }
index($0, "<script id=" Q "MathJax-script" Q) {
  if (MJ != "-") { print "<script id=" Q "MathJax-script" Q ">"; put(MJ); print "</script>" }
  else { print subst($0) }
  next
}
{ print subst($0) }
' "$tpl" > "$out"
echo "wrote $out"
