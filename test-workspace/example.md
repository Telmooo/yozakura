# Yozakura Theme - Markdown Example

> 夜桜 (yozakura)

This document showcases **every** Markdown feature to test theme syntax highlighting.

---

## Table of Contents

1. [Typography](#typography)
2. [Lists](#lists)
3. [Code](#code)
4. [Tables](#tables)
5. [Links & Images](#links--images)
6. [Blockquotes](#blockquotes)
7. [Task Lists](#task-lists)
8. [HTML in Markdown](#html-in-markdown)

---

## Typography

Normal paragraph text with **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `inline code`.

You can also use __underscores__ for _emphasis_ and combine them: **_bold italic_**.

Superscript: 10^2^ and subscript: H~2~O (if supported).

==Highlighted text== (if supported by renderer).

Here is a long paragraph to test line wrapping and how the theme handles prose text. The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!

---

## Headings

# Heading Level 1
## Heading Level 2
### Heading Level 3
#### Heading Level 4
##### Heading Level 5
###### Heading Level 6

Alternate Heading 1
===================

Alternate Heading 2
-------------------

---

## Lists

### Unordered

- Item one
- Item two
  - Nested item 2.1
  - Nested item 2.2
    - Deeply nested 2.2.1
    - Deeply nested 2.2.2
- Item three

* Asterisk item
* Another asterisk item

### Ordered

1. First item
2. Second item
   1. Nested ordered 2.1
   2. Nested ordered 2.2
3. Third item
4. Fourth item

### Loose List

- First item

  With a second paragraph.

- Second item

  With its own paragraph.

---

## Code

### Inline Code

Use `const` instead of `var` in modern JavaScript. Call `Array.prototype.map()` to transform arrays.

### Fenced Code Blocks

```javascript
// JavaScript
import { useState, useEffect } from "react";

function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue);

  useEffect(() => {
    document.title = `Count: ${count}`;
  }, [count]);

  return {
    count,
    increment: () => setCount((c) => c + 1),
    decrement: () => setCount((c) => c - 1),
    reset: () => setCount(initialValue),
  };
}
```

```typescript
// TypeScript
interface Config<T extends Record<string, unknown> = Record<string, unknown>> {
  readonly id: string;
  data: T;
  validate(): boolean;
}

type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T;
```

```python
# Python
from dataclasses import dataclass
from typing import Generator

@dataclass
class TreeNode:
    value: int
    left: "TreeNode | None" = None
    right: "TreeNode | None" = None

def inorder(node: TreeNode | None) -> Generator[int, None, None]:
    if node is None:
        return
    yield from inorder(node.left)
    yield node.value
    yield from inorder(node.right)
```

```rust
// Rust
use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum Token {
    Number(f64),
    Identifier(String),
    Operator(char),
    EOF,
}

impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Token::Number(n)     => write!(f, "{}", n),
            Token::Identifier(s) => write!(f, "{}", s),
            Token::Operator(c)   => write!(f, "{}", c),
            Token::EOF           => write!(f, "EOF"),
        }
    }
}
```

```sql
-- SQL
WITH ranked_users AS (
  SELECT
    id,
    name,
    score,
    RANK() OVER (PARTITION BY department ORDER BY score DESC) AS rank
  FROM users
  WHERE active = TRUE
)
SELECT * FROM ranked_users WHERE rank <= 3;
```

```bash
#!/usr/bin/env bash
# Bash
deploy() {
  local env="${1:-staging}"
  echo "Deploying to ${env}..."
  git tag "v$(date +%Y%m%d)" && git push --tags
}
```

```json
{
  "name": "yozakura",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "test": "vitest"
  }
}
```

```css
/* CSS */
.button {
  --btn-bg: #c792ea;
  background: var(--btn-bg);
  padding: 0.5rem 1rem;
  border-radius: 6px;
  transition: background 0.2s ease;
}
```

Indented code block (4 spaces):

    function hello() {
      console.log("world");
    }

---

## Tables

### Simple Table

| Language   | Typing  | Paradigm           | Year |
|:-----------|:-------:|-------------------:|:-----|
| JavaScript | Dynamic | Multi-paradigm     | 1995 |
| TypeScript | Static  | Multi-paradigm     | 2012 |
| Python     | Dynamic | Multi-paradigm     | 1991 |
| Rust       | Static  | Systems            | 2015 |
| Go         | Static  | Concurrent/Systems | 2009 |
| Java       | Static  | OOP                | 1995 |

### Table with Code

| Operator | JavaScript     | Python        | Rust          |
|----------|---------------|---------------|---------------|
| Nullish  | `a ?? b`       | `a or b`      | `a.unwrap_or(b)` |
| Optional | `a?.b`         | `getattr(a,'b',None)` | `a.as_ref().map(\|x\| &x.b)` |
| Spread   | `{...a, ...b}` | `{**a, **b}`  | N/A           |

---

## Links & Images

### Inline Links

[GitHub](https://github.com) - [VSCode Marketplace](https://marketplace.visualstudio.com)

[Link with title](https://example.com "Example Domain")

### Reference Links

This is a [reference link][ref1] and another [reference][ref2] here.

[ref1]: https://example.com "Reference 1"
[ref2]: https://github.com

### Autolinks

<https://example.com>

<hello@example.com>

### Images

![Alt text for logo](../icon.png "Yozakura Logo")

[![Build Status](https://img.shields.io/badge/build-passing-green)](https://github.com)

---

## Blockquotes

> Simple single-line blockquote.

> Multi-line blockquote.
> Second line continues here.
> Third line.

> ### Blockquote with heading
>
> Blockquote with **bold** and `code` and a [link](https://example.com).
>
> > Nested blockquote goes here.
> >
> > > Doubly nested.

---

## Task Lists

- [x] Create JavaScript example
- [x] Create TypeScript example
- [x] Create Python example
- [x] Create Rust example
- [x] Create Go example
- [x] Create Java example
- [x] Create C++ example
- [x] Create HTML example
- [x] Create CSS example
- [x] Create SCSS example
- [x] Create JSON example
- [x] Create Markdown example
- [ ] Create Bash example
- [ ] Create SQL example
- [ ] Create YAML example

---

## Footnotes

Here is a sentence with a footnote[^1].

Another footnote reference[^longnote].

[^1]: This is the first footnote.
[^longnote]: Here's a longer footnote with multiple paragraphs.

    Indent paragraphs to include them in the footnote.

    `code` works too.

---

## Horizontal Rules

Three hyphens:

---

Three asterisks:

***

Three underscores:

___

---

## HTML in Markdown

<div class="custom-block" style="padding: 1rem; border-left: 4px solid #c792ea;">
  <strong>Note:</strong> This is raw HTML inside Markdown.
  <br />
  It supports <em>inline HTML</em> and block-level elements.
</div>

<details>
  <summary>Click to expand</summary>

  Hidden content goes here. You can put **Markdown** inside HTML blocks too.

  ```python
  print("Hidden code!")
  ```

</details>

<kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> opens the command palette.

---

## Definition Lists (if supported)

Term 1
: Definition for term 1

Term 2
: First definition for term 2
: Second definition for term 2

---

## Escaping

\*This is not italic\*

\`This is not code\`

\[This is not a link\](https://example.com)

Backslash: \\

---

## Special Characters & Entities

&copy; 2026 &mdash; All rights reserved &trade;

&lt;html&gt; &amp; &quot;strings&quot;

---

*Last updated: 2026-03-28*
