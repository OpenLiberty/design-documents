#!/usr/bin/env python3
import sys
import re

def check_log(log_path, tex_path=None):
    with open(log_path, "r", errors="ignore") as f:
        log_content = f.read()

    tex_lines = []
    if tex_path:
        try:
            with open(tex_path, "r", errors="ignore") as f:
                tex_lines = f.readlines()
        except Exception:
            pass

    # Match overfull vbox with line numbers in LaTeX output
    # Pattern: Overfull \vbox (Xpt too high) detected at line Y
    matches = list(re.finditer(r"Overfull \\vbox \(([0-9.]+)pt too high\)(?: detected at line (\d+))?", log_content))

    if not matches:
        print("\033[32m✔ Slide overflow check passed: No overflowing slides detected.\033[0m")
        return 0

    print(f"\033[31m✖ Slide overflow warning: Found {len(matches)} overflowing slide(s)!\033[0m")
    for m in matches:
        overflow_pt = float(m.group(1))
        line_num = int(m.group(2)) if m.group(2) else None
        
        frame_title = "Unknown"
        if line_num and tex_lines:
            # Search backwards from line_num to find \begin{frame}{...} or \begin{frame}[...]{...} or \frametitle{...}
            start = max(0, line_num - 1)
            for i in range(start, max(0, start - 100), -1):
                line = tex_lines[i]
                # Look for frame title in \begin{frame}...{Title} or \frametitle{Title}
                title_match = re.search(r"\\begin\{frame\}(?:\[[^\]]*\])?\{([^}]+)\}", line)
                if not title_match:
                    title_match = re.search(r"\\frametitle\{([^}]+)\}", line)
                if title_match:
                    frame_title = title_match.group(1)
                    break
        
        print(f"  \033[33m• Slide '{frame_title}' (line {line_num if line_num else '?'}): {overflow_pt:.1f}pt too high\033[0m")

    return 1

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: check-overflow.py <xelatex.log> [source.tex]")
        sys.exit(1)
    tex_file = sys.argv[2] if len(sys.argv) > 2 else None
    sys.exit(check_log(sys.argv[1], tex_file))
