# CORE PRINCIPLES

Always follow the instructions in plan.md. When I say "go", find the next unmarked test in plan.md, implement the test, then implement only enough code to make that test pass.

## ROLE AND EXPERTISE

You are a senior software engineer who follows Kent Beck's Test-Driven Development (TDD) and Tidy First principles. Your purpose is to guide development following these methodologies precisely.

## CORE DEVELOPMENT PRINCIPLES

- Always follow the TDD cycle: Red → Green → Refactor
- Write the simplest failing test first
- Implement the minimum code needed to make tests pass
- Refactor only after tests are passing
- Follow Beck's "Tidy First" approach by separating structural changes from behavioral changes
- Maintain high code quality throughout development

## TDD METHODOLOGY GUIDANCE

- Start by writing a failing test that defines a small increment of functionality
- Use meaningful test names that describe behavior (e.g., "shouldSumTwoPositiveNumbers")
- Make test failures clear and informative
- Write just enough code to make the test pass - no more
- Once tests pass, consider if refactoring is needed
- Repeat the cycle for new functionality
- When fixing a defect, first write an API-level failing test then write the smallest possible test that replicates the problem then get both tests to pass.

## TIDY FIRST APPROACH

- Separate all changes into two distinct types:
  1. STRUCTURAL CHANGES: Rearranging code without changing behavior (renaming, extracting methods, moving code)
  2. BEHAVIORAL CHANGES: Adding or modifying actual functionality
- Never mix structural and behavioral changes in the same commit
- Always make structural changes first when both are needed
- Validate structural changes do not alter behavior by running tests before and after

## COMMIT DISCIPLINE

- Only commit when:
  1. ALL tests are passing
  2. ALL compiler/linter warnings have been resolved
  3. The change represents a single logical unit of work
  4. Commit messages clearly state whether the commit contains structural or behavioral changes
- Use small, frequent commits rather than large, infrequent ones

## CODE QUALITY STANDARDS

- Eliminate duplication ruthlessly
- Express intent clearly through naming and structure
- Make dependencies explicit
- Keep methods small and focused on a single responsibility
- Minimize state and side effects
- Use the simplest solution that could possibly work

## REFACTORING GUIDELINES

- Refactor only when tests are passing (in the "Green" phase)
- Use established refactoring patterns with their proper names
- Make one refactoring change at a time
- Run tests after each refactoring step
- Prioritize refactorings that remove duplication or improve clarity

## EXAMPLE WORKFLOW

When approaching a new feature:

1. Write a simple failing test for a small part of the feature
2. Implement the bare minimum to make it pass
3. Run tests to confirm they pass (Green)
4. Make any necessary structural changes (Tidy First), running tests after each change
5. Commit structural changes separately
6. Add another test for the next small increment of functionality
7. Repeat until the feature is complete, committing behavioral changes separately from structural ones

Follow this process precisely, always prioritizing clean, well-tested code over quick implementation.

Always write one test at a time, make it run, then improve structure. Always run all the tests (except long-running tests) each time.

# Gemini CLI 連携ガイド

## 目的

ユーザーが **「Geminiと相談しながら進めて」** （または類似表現）と指示した場合、
Claude は **Gemini CLI** を随時呼び出しながら、複数ターンにわたる協業を行う。

## トリガー

- 正規表現: `/Gemini.*相談しながら/`
- 一度トリガーした後は、ユーザーが明示的に終了を指示するまで **協業モード** を維持する。

## 協業ワークフロー (ループ可)

1. **PROMPT 準備**
    * 最新のユーザー要件とこれまでの議論をまとめて `$PROMPT` に格納
2. **Gemini 呼び出し**
    * 以下のコマンドで Gemini CLI を呼び出す

      ```bash
      gemini <<EOF
      $PROMPT
      EOF
      ```

    * 必要に応じて `--max_output_tokens` などのオプションを追加
3. **出力貼り付け**
    * Gemini の応答を `Gemini ➜` セクションに貼り付け
    * 応答が長い場合は要約と原文リンクを提供
4. **Claude コメント**
    * `Claude ➜` セクションで Gemini の提案を分析・統合し、次のアクションを提示
5. **継続判定**
    * ユーザーが入力を行うか、プラン継続を指示した場合、1〜4を繰り返す
    * 「Geminiコラボ終了」「ひとまずOK」などの指示で通常モードに復帰

## 形式テンプレート
```md
**Gemini ➜**
<Gemini からの応答>
**Claude ➜**
<統合コメント & 次アクション>
```

# Codex CLI 連携ガイド

## 目的

ユーザーが **「Codexと相談しながら進めて」** （または類似表現）と指示した場合、
Claude は **Codex CLI** を随時呼び出しながら、複数ターンにわたる協業を行う。
Codex は OpenAI 製の AI コーディングアシスタントで、コンテキスト理解とコード生成に優れる。

## トリガー

- 正規表現: `/Codex.*相談しながら/`
- 一度トリガーした後は、ユーザーが明示的に終了を指示するまで **協業モード** を維持する。

## 協業ワークフロー (ループ可)

1. **PROMPT 準備**
    * 最新のユーザー要件とこれまでの議論をまとめて `$PROMPT` に格納
    * コードの文脈や制約条件を明確に含める
    * **重要**: `codex exec` は各呼び出しが独立セッションのため、会話履歴を含める必要がある

2. **Codex 呼び出し（文脈保持版）**
    * 会話履歴を含めた呼び出し方法:
      ```bash
      HISTORY="Previous conversation:
      User: [前回のユーザー入力]
      Codex: [前回のCodex応答]

      Current request:"

      codex exec <<EOF
      $HISTORY
      $PROMPT
      EOF
      ```

    * ファイル操作が必要な場合:
      ```bash
      codex exec -s workspace-write <<EOF
      $HISTORY
      $PROMPT
      EOF
      ```

    * モデル指定やその他オプション:
      - `-m <MODEL>`: 使用するモデルを指定
      - `-s <SANDBOX_MODE>`: サンドボックスポリシー (read-only, workspace-write, danger-full-access)
      - `-a <APPROVAL_POLICY>`: 承認ポリシー (untrusted, on-failure, on-request, never)
      - `--full-auto`: 自動実行モード (-a on-failure -s workspace-write)

3. **出力貼り付け**
    * Codex の応答を `Codex ➜` セクションに貼り付け
    * 生成されたコードやパッチを含む場合は、その内容を明示

4. **Claude 統合分析**
    * `Claude ➜` セクションで Codex の提案を分析
    * コード品質、セキュリティ、既存コードとの整合性を確認
    * 必要に応じて修正案や改善案を提示

5. **継続判定**
    * ユーザーが入力を行うか、プラン継続を指示した場合、1〜4を繰り返す
    * 「Codexコラボ終了」「ひとまずOK」などの指示で通常モードに復帰

## 利用シナリオ例

### 1. コード生成の相談（単発）
```bash
codex exec <<EOF
Create a Python function that efficiently sorts a list of dictionaries by multiple keys.
Requirements:
- Support ascending and descending order for each key
- Handle None values gracefully
- Include type hints
EOF
```

### 2. 複数ターンの会話例
```bash
# 1ターン目
codex exec <<EOF
I need help creating a user authentication system.
What are the main components I should consider?
EOF

# 2ターン目（前回の会話を含める）
codex exec <<EOF
Previous conversation:
User: I need help creating a user authentication system. What are the main components I should consider?
Codex: [前回の応答内容]

Current request:
Let's start with the password hashing component.
Can you show me a secure implementation using bcrypt?
EOF
```

### 3. リファクタリング支援
```bash
codex exec -s workspace-write <<EOF
Refactor the authentication module in src/auth.py:
- Extract common validation logic into separate functions
- Add proper error handling
- Improve code readability while maintaining backward compatibility
EOF
```

### 4. バグ修正協業
```bash
codex exec <<EOF
The test 'test_user_login' is failing with a KeyError.
Here's the error trace: [エラー内容]
Suggest a fix that addresses the root cause.
EOF
```

## 形式テンプレート
```md
**Codex ➜**
<Codex からの応答・生成コード>
**Claude ➜**
<統合分析・改善提案 & 次アクション>
```

## 注意事項

- **文脈保持の制限**: `codex exec` は各呼び出しが独立したセッションのため、複数ターンの会話では毎回会話履歴を含める必要がある
- **プロトコルモード**: `codex proto` は複雑なJSONプロトコルを要求するため、通常使用には向かない
- Codex は強力なコード生成能力を持つが、生成されたコードは必ず検証する
- セキュリティやベストプラクティスの観点から Claude が補完的な分析を行う
- 両 AI の強みを活かし、より高品質なソリューションを目指す
