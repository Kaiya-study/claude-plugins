# kaiya-plugins

Claude Code のプラグイン置き場です。いまは1つだけ入っています。

| プラグイン | 何をするもの |
|---|---|
| **[my-edition](plugins/my-edition/)** | 参考書のスキャンから、**自分のレベルに合わせて行間を補完した「マイ教科書」**を作る |

---

## 導入のしかた

**ターミナルは使いません。**設定ファイルに数行足して、あとは画面から入れるだけです。

### 1. 設定ファイルに、置き場所を教える

下のファイルを開きます。無ければ新しく作ってください。

| | 場所 |
|---|---|
| Windows | `C:\Users\〔あなた〕\.claude\settings.json` |
| macOS | `~/.claude/settings.json` |

`extraKnownMarketplaces` に、次の1ブロックを足します。

```json
{
  "extraKnownMarketplaces": {
    "kaiya-plugins": {
      "source": {
        "source": "github",
        "repo": "Kaiya-study/claude-plugins"
      }
    }
  }
}
```

**すでに中身がある場合は、消さずに足してください。**
`extraKnownMarketplaces` の項目がすでにあることが多いので、その中にキーを1つ増やす形になります。

自信がなければ、**Claude に頼んでも構いません。**
「`~/.claude/settings.json` に kaiya-plugins のマーケットプレイスを追加して」と言えば、
既存の設定を保ったまま書き足してくれます。

### 2. アプリを開き直す

設定は起動時に読まれます。**開いているセッションがあれば、開き直してください。**

### 3. 画面から入れる

プロンプト欄の **＋ → Plugins → Add plugin**。一覧に `my-edition` が出るので、選んで入れます。
（サイドバーの **Customize → Plugins** からでも同じことができます）

**入れる範囲は「ユーザー」を選んでください。**そうすれば、どのフォルダで作業しても使えます。

ターミナルが使える人は、次の2行でも同じです。

```
/plugin marketplace add Kaiya-study/claude-plugins
/plugin install my-edition@kaiya-plugins
```

---

## 使うのに必要なもの

- **Claude の有料プラン**（Pro 以上）。**無料プランでは Claude Code そのものが使えません**
  （[公式ドキュメント](https://code.claude.com/docs/en/setup#authenticate)。2026年9月9日現在）
- **Claude デスクトップアプリの Code タブ**（**Chat タブでは動きません**）

GitHub のアカウントも git も要りません。公開リポジトリを読みに行くだけです。

---

## ライセンス

MIT（[LICENSE](LICENSE)）。

`my-edition` は数式の表示に [MathJax](https://www.mathjax.org/)（Apache-2.0）を使いますが、
**同梱していません。**最初の組版のときに一度だけ取得して、以後は使い回します。
