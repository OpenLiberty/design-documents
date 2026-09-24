#!/usr/bin/env python3
"""
generate-handouts.py

Generates presentation formats with speaker notes:
1. Notes PDF (1 slide on top, formatted speaker notes below, portrait Letter/A4)
2. Handout PDF (portrait, slide image top, notes below, no speaker instructions)
3. Speakernotes PDF (like handout but includes instruction boxes)

Changebar support: reads slides/changes.json (written by mark-changes.py) and
renders a red left-rule indicator next to notes/instructions that changed, and
a "◀ slide changed" badge next to the slide title when the slide body changed.
"""

import json
import sys
import os
import re
import subprocess

def parse_markdown_slides(slide_files):
    slides = []
    
    with open(slide_files[0], 'r', encoding='utf-8') as f:
        content = f.read()
    
    main_title = "Upcoming Feature Overview"
    m_title = re.search(r'^title:\s*["\']?(.*?)["\']?$', content, re.M)
    if m_title:
        main_title = m_title.group(1)

    epics_label = "UFO"
    m_epics = re.search(r'^epics:\s*["\']?(.*?)["\']?$', content, re.M)
    if m_epics:
        epics_label = m_epics.group(1).strip()

    slides.append({
        "slide_num": 1,
        "title": main_title,
        "notes": "",
        "instruction": "Title slide — introduce yourself, the feature, and the associated epics."
    })

    for filepath in slide_files[1:]:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        current_title = None
        current_notes = []
        current_instruction = []
        in_notes = False
        in_instruction = False
        
        for line in lines:
            if line.startswith('# '):
                if current_title is not None:
                    slides.append({
                        "slide_num": len(slides) + 1,
                        "title": current_title,
                        "notes": "\n".join(current_notes).strip(),
                        "instruction": "\n".join(current_instruction).strip()
                    })
                    current_notes = []
                    current_instruction = []
                    in_notes = False
                    in_instruction = False
                
                raw_title = line[2:].strip()
                raw_title = re.sub(r'\{.*?\}', '', raw_title).strip()
                current_title = raw_title
            elif re.match(r'^:::\s+notes\s*$', line.strip()):
                in_notes = True
                in_instruction = False
            elif re.match(r'^:::\s+instruction\s*$', line.strip()):
                in_instruction = True
                in_notes = False
            elif re.match(r'^:::\s*$', line.strip()):
                in_notes = False
                in_instruction = False
            elif in_notes:
                current_notes.append(line.rstrip())
            elif in_instruction:
                current_instruction.append(line.rstrip())
        
        if current_title is not None:
            slides.append({
                "slide_num": len(slides) + 1,
                "title": current_title,
                "notes": "\n".join(current_notes).strip(),
                "instruction": "\n".join(current_instruction).strip()
            })

    return main_title, epics_label, slides

def escape_latex(text):
    text = text.replace('\\', '')
    text = text.replace('&', r'\&')
    text = text.replace('$', r'\$')
    text = text.replace('%', r'\%')
    text = text.replace('#', r'\#')
    text = text.replace('_', r'\_')
    text = text.replace('^', r'\^')
    text = text.replace('~', r'\~')
    text = text.replace('<', r'\textless{}')
    text = text.replace('>', r'\textgreater{}')

    # Bold
    text = re.sub(r'\*\*(.*?)\*\*', r'\\textbf{\1}', text)
    # Italic
    text = re.sub(r'\*(.*?)\*', r'\\textit{\1}', text)
    # Inline code
    text = re.sub(r'`(.*?)`', r'\\texttt{\1}', text)
    
    # Bullet points
    lines = []
    in_list = False
    for line in text.split('\n'):
        line_s = line.strip()
        if line_s.startswith('- ') or line_s.startswith('* '):
            if not in_list:
                lines.append(r'\begin{itemize}[leftmargin=*,itemsep=2pt,parsep=0pt]')
                in_list = True
            item_text = line_s[2:].strip()
            lines.append(r'\item ' + item_text)
        else:
            if in_list and line_s == '':
                lines.append(r'\end{itemize}')
                in_list = False
            elif in_list:
                lines.append(r'\item ' + line_s)
            else:
                lines.append(line)
    if in_list:
        lines.append(r'\end{itemize}')
    
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Change data helpers
# ---------------------------------------------------------------------------

def load_changes(slides_dir: str = "slides") -> dict:
    """
    Load changes.json produced by mark-changes.py.
    Returns a dict keyed by slide title → change flags dict.
    If the file doesn't exist, returns an empty dict (no changebars).
    """
    path = os.path.join(slides_dir, "changes.json")
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        entries = json.load(f)
    return {e["title"]: e for e in entries}


def wrap_changed(latex_body: str) -> str:
    """Wrap a block of LaTeX in a magenta left-rule tcolorbox to indicate it changed."""
    return (
        r"\begin{tcolorbox}[" "\n"
        r"    colback=white," "\n"
        r"    colframe=ufochanged," "\n"
        r"    boxrule=0pt," "\n"
        r"    leftrule=3pt," "\n"
        r"    arc=0pt," "\n"
        r"    width=\linewidth," "\n"
        r"    top=3pt,bottom=3pt,left=6pt,right=4pt" "\n"
        r"]" "\n"
        + latex_body + "\n"
        r"\end{tcolorbox}" "\n"
    )


def slide_changed_badge() -> str:
    """Small inline badge shown next to the slide title when slide body changed."""
    return (
        r"\hspace{6pt}"
        r"{\fontsize{8}{10}\selectfont\bfseries\color{ufochanged}"
        r"\raisebox{1pt}{$\blacktriangleleft$}~slide\,changed}"
    )


def generate_notes_1up(main_title, epics_label, slides, slide_pdf, output_tex, changes=None):
    tex = []
    tex.append(r'''\documentclass[11pt]{article}
\usepackage[paperwidth=254mm,paperheight=142.875mm,margin=1.5cm,top=1.8cm,bottom=1.2cm,headheight=14pt]{geometry}
\usepackage{fontspec}
\usepackage{xcolor}
\usepackage{amssymb}
\usepackage[most]{tcolorbox}
\usepackage{fancyhdr}
\usepackage{enumitem}
\usepackage{xurl}

\setmainfont{Arial}
\setsansfont{Arial}
\newfontfamily\titlefont{Trebuchet MS}

\definecolor{ufonavydark}{RGB}{32,32,62}
\definecolor{ufoteal}{RGB}{76,87,125}
\definecolor{ufoborder}{RGB}{200,205,220}
\definecolor{ufoinstruct}{RGB}{180,100,0}
\definecolor{ufoinstructbg}{RGB}{255,244,225}
\definecolor{ufochanged}{RGB}{238,83,139}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\fontsize{9}{11}\selectfont\color{ufoteal} ''' + escape_latex(epics_label) + r'''}
\fancyhead[C]{\titlefont\fontsize{9}{11}\selectfont\color{ufoteal} ''' + escape_latex(main_title) + r'''}
\fancyhead[R]{\fontsize{9}{11}\selectfont\color{ufoteal} Speaker Notes}
\fancyfoot[C]{\fontsize{9}{11}\selectfont\color{ufoteal}\thepage}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

\setlength{\parindent}{0pt}
\setlength{\parskip}{6pt}

\begin{document}
''')

    changes = changes or {}

    for s in slides:
        num = s["slide_num"]
        raw_title = s["title"]
        title = escape_latex(raw_title)
        raw_notes = s["notes"]
        raw_instruction = s.get("instruction", "")
        ch = changes.get(raw_title, {})

        notes_section = ""
        if raw_notes.strip():
            notes_body = escape_latex(raw_notes)
            inner = (
                r"{\fontsize{10}{14.5}\selectfont\color{black!90}" "\n"
                f"{notes_body}\n"
                r"}" "\n\n"
            )
            notes_section = wrap_changed(inner) if ch.get("notes_changed") else inner

        instruction_section = ""
        if raw_instruction.strip():
            instr_body = escape_latex(raw_instruction)
            inner_instr = (
                r"\begin{tcolorbox}[" "\n"
                r"    colback=ufoinstructbg," "\n"
                r"    colframe=ufoinstruct," "\n"
                r"    boxrule=0pt," "\n"
                r"    leftrule=3.5pt," "\n"
                r"    arc=0pt," "\n"
                r"    width=\linewidth," "\n"
                r"    top=5pt,bottom=5pt,left=8pt,right=6pt" "\n"
                r"]" "\n"
                r"{\fontsize{9}{12}\selectfont\bfseries\color{ufoinstruct}"
                r"\raisebox{0.5pt}{$\blacktriangleright$}~Instruction}\\" "\n"
                r"\vspace{2pt}" "\n"
                r"{\fontsize{10}{14}\selectfont\color{black!90}" "\n"
                f"{instr_body}\n"
                r"}" "\n"
                r"\end{tcolorbox}" "\n\n"
            )
            instruction_section = wrap_changed(inner_instr) if ch.get("instruction_changed") else inner_instr

        if not notes_section and not instruction_section:
            notes_section = r"\textit{(No notes for this slide.)}" + "\n\n"

        badge = slide_changed_badge() if ch.get("slide_changed") else ""
        slide_block = (
            rf"{{\titlefont\fontsize{{14}}{{17}}\selectfont\bfseries\color{{ufonavydark}} Slide {num}: {title}}}{badge}" "\n\n"
            r"\vspace{0.1cm}" "\n"
            r"\hrule height 0.6pt" "\n"
            r"\vspace{0.3cm}" "\n\n"
            f"{instruction_section}"
            f"{notes_section}"
            r"\clearpage" "\n"
        )
        tex.append(slide_block)

    tex.append(r'\end{document}')

    with open(output_tex, 'w', encoding='utf-8') as f:
        f.write("\n".join(tex))

def generate_handout_digital(main_title, epics_label, slides, slide_pdf, output_tex, changes=None):
    """Generate a digital-friendly 1-up handout (portrait, slide image top, notes below, no speaker instructions)."""
    tex = []
    tex.append(r'''\documentclass[11pt,a4paper]{article}
\usepackage[portrait,margin=2.0cm,top=2.2cm,bottom=1.8cm,headheight=14pt]{geometry}
\usepackage{graphicx}
\usepackage{fontspec}
\usepackage{xcolor}
\usepackage{amssymb}
\usepackage[most]{tcolorbox}
\usepackage{fancyhdr}
\usepackage{enumitem}
\usepackage{xurl}

\setmainfont{Arial}
\setsansfont{Arial}
\newfontfamily\titlefont{Trebuchet MS}

\definecolor{ufonavydark}{RGB}{32,32,62}
\definecolor{ufoteal}{RGB}{76,87,125}
\definecolor{ufoborder}{RGB}{200,205,220}
\definecolor{ufoinstruct}{RGB}{180,100,0}
\definecolor{ufoinstructbg}{RGB}{255,244,225}
\definecolor{ufochanged}{RGB}{238,83,139}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\fontsize{9}{11}\selectfont\color{ufoteal} ''' + escape_latex(epics_label) + r'''}
\fancyhead[C]{\titlefont\fontsize{9}{11}\selectfont\color{ufoteal} ''' + escape_latex(main_title) + r'''}
\fancyhead[R]{\fontsize{9}{11}\selectfont\color{ufoteal} Presentation Handout}
\fancyfoot[C]{\fontsize{9}{11}\selectfont\color{ufoteal}\thepage}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

\setlength{\parindent}{0pt}
\setlength{\parskip}{6pt}

\begin{document}
''')

    changes = changes or {}

    for s in slides:
        num = s["slide_num"]
        raw_title = s["title"]
        title = escape_latex(raw_title)
        raw_notes = s["notes"]
        ch = changes.get(raw_title, {})

        notes_section = ""
        if raw_notes.strip():
            notes_body = escape_latex(raw_notes)
            inner = (
                r"{\fontsize{10.5}{15}\selectfont\color{black!90}" "\n"
                f"{notes_body}\n"
                r"}" "\n\n"
            )
            notes_section = wrap_changed(inner) if ch.get("notes_changed") else inner
        else:
            notes_section = r"\textit{(No notes for this slide.)}" + "\n\n"

        badge = slide_changed_badge() if ch.get("slide_changed") else ""
        # Slide image (top ~55% of page), then title + notes below
        slide_block = (
            r"\begin{center}" "\n"
            r"  \begin{tcolorbox}[" "\n"
            r"      colback=white," "\n"
            r"      colframe=ufoborder," "\n"
            r"      boxrule=0.6pt," "\n"
            r"      arc=2.5pt," "\n"
            r"      width=0.95\linewidth," "\n"
            r"      top=2pt,bottom=2pt,left=2pt,right=2pt," "\n"
            r"      drop shadow={black!10}" "\n"
            r"  ]" "\n"
            rf"  \includegraphics[page={num},width=\linewidth]{{{slide_pdf}}}" "\n"
            r"  \end{tcolorbox}" "\n"
            r"\end{center}" "\n\n"
            r"\vspace{0.4cm}" "\n\n"
            rf"{{\titlefont\fontsize{{16}}{{20}}\selectfont\bfseries\color{{ufonavydark}} Slide {num}: {title}}}{badge}" "\n\n"
            r"\vspace{0.15cm}" "\n"
            r"\hrule height 0.8pt" "\n"
            r"\vspace{0.5cm}" "\n\n"
            f"{notes_section}"
            r"\clearpage" "\n"
        )
        tex.append(slide_block)

    tex.append(r'\end{document}')

    with open(output_tex, 'w', encoding='utf-8') as f:
        f.write("\n".join(tex))

def generate_speakernotes(main_title, epics_label, slides, slide_pdf, output_tex, changes=None):
    """Generate a speaker-notes handout: slide image top, instruction box, then notes below."""
    tex = []
    tex.append(r'''\documentclass[11pt,a4paper]{article}
\usepackage[portrait,margin=2.0cm,top=2.2cm,bottom=1.8cm,headheight=14pt]{geometry}
\usepackage{graphicx}
\usepackage{fontspec}
\usepackage{xcolor}
\usepackage{amssymb}
\usepackage[most]{tcolorbox}
\usepackage{fancyhdr}
\usepackage{enumitem}
\usepackage{xurl}

\setmainfont{Arial}
\setsansfont{Arial}
\newfontfamily\titlefont{Trebuchet MS}

\definecolor{ufonavydark}{RGB}{32,32,62}
\definecolor{ufoteal}{RGB}{76,87,125}
\definecolor{ufoborder}{RGB}{200,205,220}
\definecolor{ufoinstruct}{RGB}{180,100,0}
\definecolor{ufoinstructbg}{RGB}{255,244,225}
\definecolor{ufochanged}{RGB}{238,83,139}

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\fontsize{9}{11}\selectfont\color{ufoteal} ''' + escape_latex(epics_label) + r'''}
\fancyhead[C]{\titlefont\fontsize{9}{11}\selectfont\color{ufoteal} ''' + escape_latex(main_title) + r'''}
\fancyhead[R]{\fontsize{9}{11}\selectfont\color{ufoteal} Speaker Notes}
\fancyfoot[C]{\fontsize{9}{11}\selectfont\color{ufoteal}\thepage}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}

\setlength{\parindent}{0pt}
\setlength{\parskip}{6pt}

\begin{document}
''')

    changes = changes or {}

    for s in slides:
        num = s["slide_num"]
        raw_title = s["title"]
        title = escape_latex(raw_title)
        raw_notes = s["notes"]
        raw_instruction = s.get("instruction", "")
        ch = changes.get(raw_title, {})

        notes_section = ""
        if raw_notes.strip():
            notes_body = escape_latex(raw_notes)
            inner = (
                r"{\fontsize{10.5}{15}\selectfont\color{black!90}" "\n"
                f"{notes_body}\n"
                r"}" "\n\n"
            )
            notes_section = wrap_changed(inner) if ch.get("notes_changed") else inner

        instruction_section = ""
        if raw_instruction.strip():
            instr_body = escape_latex(raw_instruction)
            inner_instr = (
                r"\begin{tcolorbox}[" "\n"
                r"    colback=ufoinstructbg," "\n"
                r"    colframe=ufoinstruct," "\n"
                r"    boxrule=0pt," "\n"
                r"    leftrule=3.5pt," "\n"
                r"    arc=0pt," "\n"
                r"    width=\linewidth," "\n"
                r"    top=5pt,bottom=5pt,left=8pt,right=6pt" "\n"
                r"]" "\n"
                r"{\fontsize{9}{12}\selectfont\bfseries\color{ufoinstruct}"
                r"\raisebox{0.5pt}{$\blacktriangleright$}~Instruction}\\" "\n"
                r"\vspace{2pt}" "\n"
                r"{\fontsize{10}{14}\selectfont\color{black!90}" "\n"
                f"{instr_body}\n"
                r"}" "\n"
                r"\end{tcolorbox}" "\n\n"
            )
            instruction_section = wrap_changed(inner_instr) if ch.get("instruction_changed") else inner_instr

        if not notes_section and not instruction_section:
            notes_section = r"\textit{(No notes for this slide.)}" + "\n\n"

        badge = slide_changed_badge() if ch.get("slide_changed") else ""
        slide_block = (
            r"\begin{center}" "\n"
            r"  \begin{tcolorbox}[" "\n"
            r"      colback=white," "\n"
            r"      colframe=ufoborder," "\n"
            r"      boxrule=0.6pt," "\n"
            r"      arc=2.5pt," "\n"
            r"      width=0.95\linewidth," "\n"
            r"      top=2pt,bottom=2pt,left=2pt,right=2pt," "\n"
            r"      drop shadow={black!10}" "\n"
            r"  ]" "\n"
            rf"  \includegraphics[page={num},width=\linewidth]{{{slide_pdf}}}" "\n"
            r"  \end{tcolorbox}" "\n"
            r"\end{center}" "\n\n"
            r"\vspace{0.4cm}" "\n\n"
            rf"{{\titlefont\fontsize{{16}}{{20}}\selectfont\bfseries\color{{ufonavydark}} Slide {num}: {title}}}{badge}" "\n\n"
            r"\vspace{0.15cm}" "\n"
            r"\hrule height 0.8pt" "\n"
            r"\vspace{0.5cm}" "\n\n"
            f"{instruction_section}"
            f"{notes_section}"
            r"\clearpage" "\n"
        )
        tex.append(slide_block)

    tex.append(r'\end{document}')

    with open(output_tex, 'w', encoding='utf-8') as f:
        f.write("\n".join(tex))

def main():
    if len(sys.argv) < 3:
        print("Usage: generate-handouts.py <slide_pdf> <mode: notes|handout|speakernotes> [output_pdf]")
        sys.exit(1)

    slide_pdf = os.path.abspath(sys.argv[1])
    mode = sys.argv[2]

    slide_files = [
        "slides/00-title.md",
        "slides/01-design-thinking.md",
        "slides/02-feature-design.md",
        "slides/03-quality.md"
    ]

    main_title, epics_label, slides = parse_markdown_slides(slide_files)
    changes = load_changes("slides")

    build_dir = "build"
    os.makedirs(build_dir, exist_ok=True)

    if mode == "notes":
        tex_file = os.path.join(build_dir, "notes-1up.tex")
        out_pdf = sys.argv[3] if len(sys.argv) > 3 else "notes.pdf"
        generate_notes_1up(main_title, epics_label, slides, slide_pdf, tex_file, changes)
        subprocess.run(["xelatex", "-interaction=nonstopmode", f"-output-directory={build_dir}", tex_file], check=True)
        built_pdf = os.path.join(build_dir, "notes-1up.pdf")
        if os.path.exists(built_pdf):
            os.replace(built_pdf, out_pdf)
            print(f"Generated {out_pdf}")
    elif mode == "handout":
        tex_file = os.path.join(build_dir, "handout-digital.tex")
        out_pdf = sys.argv[3] if len(sys.argv) > 3 else "handout.pdf"
        generate_handout_digital(main_title, epics_label, slides, slide_pdf, tex_file, changes)
        subprocess.run(["xelatex", "-interaction=nonstopmode", f"-output-directory={build_dir}", tex_file], check=True)
        built_pdf = os.path.join(build_dir, "handout-digital.pdf")
        if os.path.exists(built_pdf):
            os.replace(built_pdf, out_pdf)
            print(f"Generated {out_pdf}")
    elif mode == "speakernotes":
        tex_file = os.path.join(build_dir, "speakernotes.tex")
        out_pdf = sys.argv[3] if len(sys.argv) > 3 else "speakernotes.pdf"
        generate_speakernotes(main_title, epics_label, slides, slide_pdf, tex_file, changes)
        subprocess.run(["xelatex", "-interaction=nonstopmode", f"-output-directory={build_dir}", tex_file], check=True)
        built_pdf = os.path.join(build_dir, "speakernotes.pdf")
        if os.path.exists(built_pdf):
            os.replace(built_pdf, out_pdf)
            print(f"Generated {out_pdf}")
    else:
        print(f"Unknown mode: {mode}")
        sys.exit(1)

if __name__ == "__main__":
    main()
