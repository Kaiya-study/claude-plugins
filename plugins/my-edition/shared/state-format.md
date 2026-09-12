# 作業ディレクトリと状態ファイルの仕様

すべての状態は、スキャン画像フォルダの隣に作る `.my-edition/` に置く。
1冊の作業は数日から数週間にわたり、会話の文脈は毎回消えるため、進捗は必ずファイルに持たせる。

```
<本のフォルダ>/
├── scans/              ← 読者が用意したスキャン画像（触らない）
├── src/                ← 本文データがある場合はここ（触らない）
└── .my-edition/
    ├── state.json      ← 本の構造・オフセット・進捗
    ├── ledger.md       ← 式と記号の台帳（追記型）
    ├── text/           ← OCR結果（まとまり単位）
    │   └── ch03-01.md
    ├── gaps/           ← 行間の補完（まとまり単位）
    │   └── ch03-01.md
    ├── b64/            ← 図の base64（1図1ファイル・1行）
    │   └── p026_fig1.txt
    ├── parts/          ← 組版の断片（自分が書くのはここだけ）
    │   ├── title.txt
    │   ├── rail.html   ← サイドバー
    │   ├── ch03.html   ← 本文。章ごとに1つ
    │   └── colophon.html ← 巻末。いちばん最後に連結する
    └── out/            ← 生成されたマイ教科書（読者が開くのはここ）
        └── book.html   ← 既定は全章まとめて1ファイル
```

**本に属さないものは、ここに置かない。**次の2つは資料をまたいで1つだけ持つ
（Windows は `%USERPROFILE%\my-textbooks\`）。

```
~/my-textbooks/
├── profile.md          ← 読者の学力プロファイル。写真の経路と共通
└── assets/
    └── tex-svg.js      ← MathJax。本が増えても 2.1MB は1つだけ
```

理由は2つ。**三択（既知／怪しい／未習）は本ではなく人の属性**なので、本ごとに持つと
2冊目でまた同じことを聞くことになる。MathJax は本ごとに落とすと、そのぶん重複する。

単一の `profile.md` が無く、本の中に古い `.my-edition/profile.md` がある場合は、
**それを引き上げて使う。**聞き直さない。

## state.json

```json
{
  "book": {
    "title": "熱学・統計力学",
    "source": "scans",
    "scanDir": "scans",
    "filePattern": "page_%03d.jpg",
    "firstFile": 1,
    "lastFile": 412
  },
  "calibration": {
    "mode": "offset",
    "offset": 11,
    "probes": [
      { "file": 50, "printed": 39 },
      { "file": 350, "printed": 339 }
    ],
    "verified": true
  },
  "chapters": [
    {
      "no": 3,
      "title": "熱力学関数と平衡条件",
      "printed": [87, 124],
      "files": [97, 136],
      "sections": [
        { "no": "3.4", "printed": 96 }
      ],
      "units": [
        { "id": "ch03-01", "files": [97, 108], "status": "built", "textFrom": "ocr" },
        { "id": "ch03-02", "files": [109, 120], "status": "filled", "textFrom": "ocr" },
        { "id": "ch03-03", "files": [121, 136], "status": "pending", "textFrom": "ocr" }
      ]
    }
  ],
  "appendix": { "title": "付録A 記号一覧", "printed": [398, 404], "files": [408, 414] },
  "ledgerCoverage": { "printed": [87, 120], "appendix": true },
  "mode": "claude-only",
  "usage": { "unitsThisSession": 2, "lastRunAt": "2026-09-02T10:00:00Z" }
}
```

### フィールドの意味

- `book.source` — `scans`（既定・画像から起こす）／`text`（本文データが手元にある）／`mixed`（章によって違う）
- `calibration.mode` — `offset`（印刷ページ番号＋一定のオフセット）／`perChapterFolder`（章ごとにフォルダが分かれており較正不要）／`runningHead`（柱で判定）
- `units` — 12ページ前後の投入単位。`status` は `pending` → `ocr` → `checked` → `filled` → `built` の順に進む
- `units[].textFrom` — `ocr`（この道具が画像から起こした）／`provided`（読者が持ち込んだ本文）。
  **`provided` の単位は取り込み工程を飛ばす。**下記

## 本文データが手元にある場合

原著の LaTeX ソース、文字起こし済みのテキスト、テキスト層のあるPDFなどが手元にあるなら、
**スキャンと取り込みを飛ばせる。**いちばん重い工程が丸ごと消える。

```json
"book": {
  "title": "熱学・統計力学",
  "source": "text",
  "srcDir": "src",
  "srcNote": "原著者が配布している LaTeX ソース"
}
```

- 本文データは `src/` に置いてもらい、**触らない**。`.my-edition/text/<unit-id>.md` へ
  まとまり単位に切り出してコピーする。切り出す以外の加工をしない
- その単位の `textFrom` を `provided` にし、`status` を `checked` から始める
- **較正は要らない。**印刷ページ番号との対応は本文データ側の構造から取る
- 台帳は、取り込み工程の代わりに**本文データから作る**。式・記号・図の拾い出しは同じ

### 忠実性の扱いが変わる

**持ち込まれた本文の忠実さは、この道具では保証できない。**
`ocr` の工程は「原文を直さない」ための仕組みを持っているが、
すでにあるテキストには、その保護がかかっていない。元がどう作られたか次第である。

- `srcNote` に**出どころを必ず残す**。あとで疑わしい箇所が出たときに、どこまで遡れるか判断できる
- 組版のときは `editors-note` に「本文は読者が用意したデータを使っている」旨を入れる
- 原本の画像もあるなら `scanDir` を併記しておく。**疑わしい箇所だけ原本に当たれる**ようになる
- `ledgerCoverage` — 台帳がカバーしている印刷ページの範囲。行間埋めのときに参照先がここに入っているかを判定する
- `mode` — `claude-only`（既定）／`gemini`（OCRを外部に出している）
- `usage.unitsThisSession` — このセッションで投入したまとまり数。3に近づいたら利用上限を知らせる

## 進捗の扱い

- 作業を始める前に必ず `state.json` を読み、どこまで終わっているかを確認する
- 1まとまり終えるたびに `state.json` を更新する。まとめて最後に書かない
- ファイルが存在しないときは、`setup` がまだ実行されていない。`setup` を先に案内する
