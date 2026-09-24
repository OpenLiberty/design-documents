# Changebar Examples {.unnumbered}

```{=latex}
\sectionslide{Conditional Gizmo Propagation}
```

# Ex 1: Whole block changed

- Enabling `acme-gizmo-2.0` causes Gizmo protocol context to propagate globally

::: changed
- Calls to legacy / 3rd-party doodads fail when Gizmo headers are rejected
- Need to allow propagation **only** to doodads that declare `<acme:GizmoSupport>`
:::

- Retain unconditional propagation as the default for zero-migration compatibility


::: notes
Example 1: a fenced ::: changed div wraps two bullets in the middle of the list.
The changebar appears only alongside those two lines.
:::

# Ex 2: Inline addition

::: changed
- **Opt-In** — `<acme-gizmo propagation="conditional"/>`:
  Gizmo headers attached only to [`<acme:GizmoSupport>`]{.added} doodads
:::

- **Zero-Migration** — `<acme-gizmo propagation="always"/>`: existing widgets unaffected
- **Outbound Suppression** — `<acme-gizmo propagation="never"/>`: no Gizmo headers on any outbound call


::: notes
Example 2: {.added} inside a ::: changed block — the colorbox highlights the new
inline text while the margin bar marks the whole bullet as changed. For a whole new
bullet use ::: changed alone; for a word or phrase within an existing bullet combine
both.
:::

# Ex 3: Inline deletion

- The `propagation` attribute accepts: [`always`]{.deleted} [`always` (default)]{.added}, `conditional`, `never`
- Default remains `always` for zero-migration compatibility


::: notes
Example 3: [old text]{.deleted} renders with strikethrough; [new text]{.added}
immediately follows. Both get a changebar.
:::

# Ex 4: Whole new diagram

```{=latex}
\definecolor{ufocvdblue}{RGB}{0,114,178}
\begin{center}
\begin{tikzpicture}[
  % top/mid nodes: 7cm wide, centred at x=0
  box/.style={rectangle, draw=ufoteal, fill=white, thick,
              text width=7cm, minimum height=0.55cm,
              align=center, rounded corners=3pt, font=\sffamily\small},
  chk/.style={rectangle, draw=ufocvdblue, fill=ufocvdblue!10, thick,
              text width=7cm, minimum height=0.58cm,
              align=center, rounded corners=3pt, font=\sffamily\small},
  % leaf nodes: 3cm wide, centred at x = ±2.2
  leaf/.style={rectangle, draw=ufoteal, fill=white, thick,
               text width=3cm, minimum height=0.55cm,
               align=center, rounded corners=3pt, font=\sffamily\small},
  line/.style={draw=ufonavydark, -latex, thick},
  newline/.style={draw=ufocvdblue, -latex, thick},
  lbl/.style={font=\sffamily\scriptsize\bfseries, color=ufocvdblue}]
  \node[box]  (desc) at ( 0,    0) {Fetch MacGuffin Descriptor};
  \node[chk]  (pol)  at ( 0, -1.1) {Contains \texttt{<acme:GizmoSupport>}?};
  \node[leaf] (yes)  at (-2.2, -2.2) {Attach Gizmo headers};
  \node[leaf] (no)   at ( 2.2, -2.2) {Plain request only};
  \draw[newline] (desc) -- (pol);
  \draw[newline] (pol.west) -- ++(-0.5,0) |-
    node[above,near start,lbl]{Yes} (yes);
  \draw[newline] (pol.east) -- ++( 0.5,0) |-
    node[above,near start,lbl]{No}  (no);
  % Changebar: vertical rule in the far left margin, clear of all content.
  % Leftmost content: leaf node left edge = -2.2-1.5 = -3.7cm;
  % arrow stub extends to x = -4.0cm. Bar at x = -5.0 clears everything.
  \draw[ufochanged, line width=2.5pt, line cap=round]
    (-5.0, 0.35) -- (-5.0, -2.55);
\end{tikzpicture}
\end{center}
```

::: notes
Example 4: whole new diagram — draw a vertical changebar just outside the
leftmost node using a fixed x coordinate. No highlight ring needed; the bar on
the left margin is the established convention, matching how ::: changed renders
on bullet slides.
:::

# Ex 5: New elements inside an existing diagram

```{=latex}
\usetikzlibrary{fit}
\definecolor{ufocvdblue}{RGB}{0,114,178}
\begin{center}
\begin{tikzpicture}[remember picture,
  box/.style={rectangle, draw=ufoteal, fill=white, thick,
              text width=8.5cm, minimum height=0.55cm,
              align=center, rounded corners=3pt, font=\sffamily\small},
  chk/.style={rectangle, draw=ufonavydark, fill=ufonavydark!6, thick,
              text width=8.5cm, minimum height=0.58cm,
              align=center, rounded corners=3pt, font=\sffamily\small},
  line/.style={draw=ufonavydark, -latex, thick},
  lbl/.style={font=\sffamily\scriptsize\bfseries},
  % newarrow — magenta arrow for new paths
  newarrow/.style={draw=ufochanged, -latex, thick,
                   postaction={draw=ufochanged, line width=5pt, opacity=0.18}},
  newlbl/.style={font=\sffamily\scriptsize\bfseries, color=ufochanged}]

  \node[box] (app)  at (0,  0)   {Widget Dispatch};
  \node[chk] (feat) at (0, -1.1) {\texttt{acme-gizmo-2.0} configured?};
  % New node — drawn in normal chk style
  \node[chk]  (cfg) at (0, -2.2) {Check \texttt{propagation} setting};
  \node[box] (send) at (0, -3.3) {Dispatch Widget Request};

  % Highlight ring for cfg: a fit node with inner sep padding drawn as a dashed
  % ring outside cfg's own border, leaving cfg's original appearance intact.
  \node[draw=ufochanged, line width=1.8pt, dashed,
        dash pattern=on 4pt off 2pt,
        rounded corners=5pt, fill=none,
        fit=(cfg), inner sep=4pt] {};

  \draw[line] (app)  -- (feat);
  \draw[line] (feat) -- node[right,lbl]{Yes} (cfg);
  \draw[line] (feat.west) -- ++(-1.8,0) -- ++(0,-2.2) -- (send.west);
  \node[lbl, anchor=south east] at ([xshift=-3pt]feat.west) {No};

  % New "never" path — magenta arrow with halo glow
  \draw[newarrow] (cfg.east) -- ++(1.8,0) -- ++(0,-1.1) -- (send.east);
  \node[newlbl, anchor=south west] at ([xshift=3pt]cfg.east) {never};

\end{tikzpicture}
\end{center}
```

::: notes
Example 5: new nodes use a dashed magenta highlight ring (the \texttt{fit} node
technique) drawn outside the node border, leaving the node style unchanged. New
paths use a thick magenta arrow with a semi-transparent halo glow (postaction).
The diagram reads correctly without altering any element's meaning.
:::
