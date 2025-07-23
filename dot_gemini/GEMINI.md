## Claude Code 連携ガイド

### 目的

Claude から **Gemini CLI** が呼び出された際に、 Gemini は Claude との対話コンテキストを保ちながら、複数ターンに渡り協働する。

### Claude Code の使い方

- ターミナルで以下を実行すると Claude と対話できる。

```bash
Claude <<EOF
<質問・依頼内容>
EOF
```
