# Terminal Path Pasting & Shell Injection Prevention

When users copy screenshot file paths to the clipboard for use in terminal sessions, developer shells, or scripts, unescaped file paths present potential security risks and syntax errors.

---

## 1. The Threat: Spaces & Special Shell Metacharacters

Standard macOS screenshot filenames frequently contain spaces, colons, parentheses, and timestamps:
`Screen Shot 2026-09-28 at 02.15.00.png`

If pasted directly into a POSIX shell (zsh, bash, sh) without proper quoting or escaping:
```bash
cat Screen Shot 2026-09-28 at 02.15.00.png
# Treated as multiple arguments: [Screen], [Shot], [2026-09-28], [at], [02.15.00.png]
```

Furthermore, malicious paths containing command substitution metacharacters (`$()`, `` ` ``, `;`, `&&`, `|`) could trigger arbitrary command execution if processed by automated scripts.

---

## 2. Shell Escaping Algorithm

ClipShot provides a safe path-escaping utility for all terminal clipboard actions:

```swift
public func shellEscapedPath(for url: URL) -> String {
    let path = url.path
    // Wrap entire path in single quotes and escape embedded single quotes: ' -> '\''
    let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
    return "'\(escaped)'"
}
```

### Safety Guarantees of POSIX Single Quoting:
- **No Variable Expansion**: `$VARIABLE` and `$(command)` are treated as raw literal text.
- **No Globbing**: Asterisks `*` and question marks `?` are never expanded by the shell.
- **No Word Splitting**: Spaces and tabs are preserved as a single atomic token.
- **Embedded Quotes**: Any single quote within the filename is cleanly closed, escaped with a backslash, and reopened (`'\''`).

---

## 3. Terminal Pasting Verification Matrix

| Input Path | Escaped Output | Shell Safety |
| :--- | :--- | :--- |
| `/Users/me/Desktop/shot.png` | `'/Users/me/Desktop/shot.png'` | Safe |
| `/Users/me/Screen Shot.png` | `'/Users/me/Screen Shot.png'` | Preserves spaces |
| `/tmp/test$()injection.png` | `'/tmp/test$()injection.png'` | Prevents subshell execution |
| `/tmp/developer's work.png` | `'/tmp/developer'\''s work.png'` | Escapes apostrophe |

---

## 4. Best Practices for CLI Integrations

When invoking shell scripts or terminal helpers from ClipShot:
1. Always use `Process()` with an arguments array (`process.arguments = [path]`) rather than concatenating command strings passed to `/bin/sh -c`.
2. When writing paths to `NSPasteboard` for user terminal pasting, offer the option to copy as quoted shell path.
