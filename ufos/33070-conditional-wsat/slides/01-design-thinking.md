# Design Thinking {.unnumbered}

```{=latex}
\sectionslide{Design Thinking}
```

::: instruction
This section establishes the user-centric motivation, target personas, migration hurdles, and target architecture for Conditional WS-AT.
:::

# Technical Background

- **WS-AtomicTransaction (WS-AT)** provides two-phase commit transaction coordination across distributed web services
- In **traditional WebSphere Application Server (tWAS)**:
  - Policy sets and bindings give granular control over WS-AT enablement at the individual web service / endpoint level
- In **Open Liberty**:
  - Outbound WS-AT behavior is governed by the presence of `wsAtomicTransaction-1.2` and configured via `<wsAtomicTransaction/>`
  - Unconditional propagation is the legacy default provided by `defaultInstances.xml`

::: notes
WS-AT coordinates distributed transactions across JAX-WS endpoints. While tWAS allowed per-endpoint policy set attachment, Open Liberty's wsAtomicTransaction-1.2 feature historically operated globally across all JAX-WS outbound calls.
:::

# Problem Statement

- Enabling `wsAtomicTransaction-1.2` causes WS-AT context to propagate on **all outbound requests** in a global transaction, even if the target lacks WS-AT assertions
- Calls to non-transactional / 3rd-party services fail when WS-AT headers are rejected
- **Desired outcome**: Allow transactions to be propagated to only those web services that express a WS-AT policy assertion in their WSDL:
  ```xml
  <wsp:Policy wsu:Id="WSAT_Policy">
      <wsat:ATAssertion wsp:Optional="false"/>
  </wsp:Policy>
  ```
- Retain unconditional propagation as the default for zero-migration compatibility

::: notes
Unconditional propagation breaks communication with non-transactional downstream services when an active JTA transaction exists. The desired outcome is policy-driven propagation based on the target service's WSDL assertion.

XML namespace prefixes used in the WSDL snippet:
- wsp: WS-Policy namespace (http://schemas.xmlsoap.org/ws/2004/09/policy or http://www.w3.org/ns/ws-policy), defining policy containers and assertion attributes like wsp:Optional.
- wsu: WS-Security Utility namespace (http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd), providing the wsu:Id attribute used to identify and attach policy elements.
- wsat: WS-AtomicTransaction namespace (http://docs.oasis-open.org/ws-tx/wsat/2006/06), specifying the ATAssertion element.
:::

# Interested Users

- **Enterprise Application Developers** migrating JAX-WS applications from Traditional WebSphere (tWAS) to Open Liberty
- **Integration Architects** designing composite enterprise workflows where transactional operations coexist with non-transactional external APIs (e.g., payment gateways, audit logging, notification services)
- **DevOps & Platform Teams** seeking zero-code-change migration fidelity and seamless runtime parity with tWAS policy set semantics

::: notes
Target users are primarily enterprise modernization teams moving multi-tier SOAP applications to Liberty without needing to re-architect or refactor existing transactional orchestration code.
:::

# High Level User Stories

- **Zero-Migration** — `<wsAtomicTransaction propagation="always"/>`:
  - *As an existing Liberty user*, I want my current applications to behave identically without changes when upgrading Liberty, so that my existing deployment remains completely unbroken.
- **Opt-In** — `<wsAtomicTransaction propagation="conditional"/>`:
  - *As an enterprise developer*, I want WS-AT context attached only to endpoints that advertise `<wsat:ATAssertion>`, so that non-transactional services are called cleanly without manual transaction suspension.
- **Outbound Suppression** — `<wsAtomicTransaction propagation="never"/>`:
  - *As an administrator*, I want to suppress all outbound WS-AT propagation so my server can participate in inbound transactions without forwarding context to downstream services.

::: notes
Three user stories, each tied to an explicit `<wsAtomicTransaction/>` configuration:

1. **Zero-Migration Compatibility** (`<wsAtomicTransaction/>`): No `propagation` attribute means the default of `always` applies. Existing deployments continue unconditional WS-AT propagation on all outbound calls — zero config changes required on upgrade.

2. **Opt-In Conditional Propagation** (`<wsAtomicTransaction propagation="conditional"/>`): Liberty inspects the target endpoint's WSDL for a `<wsat:ATAssertion>` policy. If present, WS-AT context is attached; if absent, the call proceeds as plain SOAP. Eliminates the need for manual `TransactionManager.suspend()` / `resume()` guards around non-transactional service calls.

3. **Outbound Suppression** (`<wsAtomicTransaction propagation="never"/>`): The server can still receive and coordinate inbound WS-AT transactions but will never inject coordination context on outbound calls. Useful for inbound-only participant servers or when all downstream targets are non-transactional.
:::

::: instruction
Cover each story in turn; invite the room to challenge whether the default of "always" truly covers their migration use case before moving on.
:::

# As-Is: Unconditional Propagation

- With `wsAtomicTransaction-1.2` enabled, any outbound JAX-WS call during a JTA transaction injects WS-AT headers
- Non-transactional / 3rd-party endpoints reject unknown headers or fail schema validation
- Developers must manually modify application source code:
  - Explicitly obtain `TransactionManager` / `UserTransaction`
  - Suspend transaction prior to invocation, then resume afterwards
  - Handle complex failure and rollback paths manually

::: notes
Today, developers must manually wrap third-party or non-transactional web service calls in transaction suspend/resume blocks, increasing code complexity and introducing transaction leak risks.
:::

# To-Be: Configurable Propagation

- **`wsAtomicTransaction-1.2` Not Enabled**: Standard plain SOAP (no WS-AT headers)
- **Default Mode (`propagation="always"` or unconfigured)**:
  - Unconditional propagation remains default via `defaultInstances.xml` (Zero-Migration)
- **Conditional Mode (`propagation="conditional"` / Opt-In)**:
  - Outbound WS-AT context attached **only** if target WSDL advertises `<wsat:ATAssertion>`
  - Non-transactional endpoints proceed cleanly without WS-AT headers
- **Suppression Mode (`propagation="never"` / Opt-In)**:
  - Outbound WS-AT context is never attached on outbound client calls
- **Zero code changes required** for migrated applications

::: notes
With propagation="conditional", Liberty inspects the endpoint policy engine. If no WS-AT assertion is declared, WS-AT headers are omitted, allowing harmonious mixed-endpoint topologies within a single transaction.
:::

# Feature Design: Runtime Interception

\begin{center}
\definecolor{ufocvdblue}{RGB}{0,114,178}
\begin{tikzpicture}[remember picture,
  box/.style={rectangle, draw=ufoteal, fill=white, thick, text width=8.5cm, minimum height=0.58cm, align=center, rounded corners=3pt, font=\sffamily\small},
  chk/.style={rectangle, draw=ufonavydark, fill=ufonavydark!6, thick, text width=8.5cm, minimum height=0.62cm, align=center, rounded corners=3pt, font=\sffamily\small},
  action/.style={rectangle, draw=ufonavydark, fill=white, thick, text width=8.5cm, minimum height=0.68cm, align=center, rounded corners=3pt, font=\sffamily\small},
  line/.style={draw=ufonavydark, -latex, thick},
  newline/.style={draw=ufocvdblue, -latex, thick},
  lbl/.style={font=\sffamily\scriptsize\bfseries},
  newlbl/.style={font=\sffamily\scriptsize\bfseries, color=ufocvdblue}]

  % All nodes centred on x=0, evenly spaced vertically
  \node[box]    (app)      at (0,  0)    {JAX-WS Outbound Client Request (Inside Global Transaction)};
  \node[chk]    (feat)     at (0, -1.2)  {\texttt{wsAtomicTransaction-1.2} feature configured?};
  \node[chk, draw=ufocvdblue, fill=ufocvdblue!10]    (cfg)      at (0, -2.4)  {Check Config: \texttt{propagation} setting};
  \node[chk, draw=ufocvdblue, fill=ufocvdblue!10]    (check)    at (0, -3.6)  {Target WSDL contains \texttt{ATAssertion}?};
  \node[action] (propagate)at (0, -4.8)  {Attach WS-AT Header ({\footnotesize\texttt{wscoor:CoordinationContext}})};
  \node[box]    (send)     at (0, -6.0)  {Transmit HTTP / SOAP Request to Target Endpoint};

  % Vertical happy path
  \draw[line] (app)      -- (feat);
  \draw[line] (feat)     -- node[right, lbl] {Yes / configured} (cfg);
  \draw[newline] (cfg)   -- node[right, newlbl] {conditional} (check);
  \draw[newline] (check) -- node[right, newlbl] {Match} (propagate);
  \draw[line] (propagate)-- (send);

  % Left side (No outermost, always inner — no crossings):
  %   No   (feat→send):   rail x = box.west - 2.4cm
  %   always (cfg→prop):  rail x = box.west - 1.4cm
  % Right side (never outermost, None inner — no crossings):
  %   never (cfg→send):   rail x = box.east + 2.4cm
  %   None (check→send):  rail x = box.east + 1.4cm

  % Left: No (feat → send, outer rail — drops past send top, enters send.west)
  \draw[line] (feat.west) -- ++(-2.4,0) -- ++(0,-4.8) -- (send.west);
  \node[lbl, anchor=south east] at ([xshift=-3pt]feat.west) {No};

  % Left: always (cfg → propagate)
  \draw[line] (cfg.west) -- ++(-1.4,0) -- ++(0,-2.4) -- (propagate.west);
  \node[lbl, anchor=south east] at ([xshift=-3pt]cfg.west) {always (Default)};

  % Right bypasses enter send.east at distinct y offsets so their
  % inbound horizontal segments are at different heights — no crossing.
  % never: outer rail — drops to below None's inbound level, arrives lower
  \draw[newline] (cfg.east) -- ++(2.4,0) -- ++(0,-3.75) -- ([yshift=-0.15cm]send.east);
  \node[newlbl, anchor=south west] at ([xshift=3pt]cfg.east) {never};

  % None: inner rail — arrives above never's inbound level
  \draw[newline] (check.east) -- ++(1.4,0) -- ++(0,-2.25) -- ([yshift=0.15cm]send.east);
  \node[newlbl, anchor=south west] at ([xshift=3pt]check.east) {None};

\end{tikzpicture}
\end{center}

::: notes
Simplified flow: if wsAtomicTransaction-1.2 is not configured, or propagation is "never", or the target WSDL has no ATAssertion, the request proceeds as plain SOAP with no WS-AT headers — a no-op. Headers are only attached when the feature is active and policy allows it.
:::

# End User Overview

```{=latex}
% IBM Carbon 14-colour categorical palette (pairing 1, light theme)
%   #1192e8  Blue-50  (index  2) — WS-AT / transactional path
%   #b28600  Yellow-50 (index 10) — plain SOAP / suppressed path
% CVD-safe: differ in both hue and luminance across all deficiency types.
\definecolor{ibmblue}{RGB}{17,146,232}
\definecolor{ibmyellow}{RGB}{178,134,0}
\usetikzlibrary{shapes.arrows}
\vspace{0.3cm}
\begin{center}
\resizebox{0.97\textwidth}{!}{%
\begin{tikzpicture}[x=1cm, y=1cm]

% ── Server box ────────────────────────────────────────────────────────────────
\node[rectangle, rounded corners=8pt,
     draw=ufonavydark, fill=ufonavydark,
     minimum width=5.8cm, minimum height=5.4cm]
  (srv) at (0, 0) {};

\node[text=white, font=\sffamily\fontsize{14}{17}\selectfont\bfseries,
      anchor=north] at ([yshift=-12pt]srv.north)
  {Liberty Server};

\node[text=white!55!ufonavydark,
      font=\ttfamily\fontsize{9}{11}\selectfont, align=center,
      anchor=north] at ([yshift=-32pt]srv.north)
  {jaxws-2.2\\[1pt]wsAtomicTransaction-1.2};

% Config snippet inset
\node[rectangle, rounded corners=4pt,
     draw=white, fill=ufonavydark!55,
     text width=4.4cm, align=center, inner sep=9pt,
     font=\ttfamily\fontsize{11}{14}\selectfont, text=white,
     anchor=north] at ([yshift=-68pt]srv.north)
  (cfg)
  {<wsAtomicTransaction\\[3pt]
   \ \ propagation=\\[3pt]
   \ \ "conditional"/>};

% Arrows sit at fixed y; tail flush with srv.east (no xshift gap).
% Upper row y=1.6, lower row y=-1.6 — symmetric about centre.

% Both arrows identical size; text vertically centred via \parbox.
% "SOAP request" on one line; "+ transaction context" smaller below it.
% \parbox forces text block width so both lines are flush-centred together.

% ── Blue arrow: SOAP request + transaction context ────────────────────────────
\node[single arrow, single arrow head extend=6pt,
     draw=ibmblue, fill=ibmblue,
     text=white, font=\sffamily\fontsize{12}{14}\selectfont\bfseries,
     minimum height=4.2cm, minimum width=1.3cm,
     inner xsep=14pt, inner ysep=0pt,
     shape border rotate=0, align=center,
     anchor=tail] at (srv.east |- 0,1.6)
  (arrtrans)
  {\parbox{2.8cm}{\centering
     {\fontsize{9}{11}\selectfont\phantom{+ transaction context}}\\[3pt]
     SOAP request\\[3pt]
     {\fontsize{9}{11}\selectfont + transaction context}\\[3pt]
     {\fontsize{9}{11}\selectfont\phantom{+ transaction context}}}};

% ── Amber arrow: SOAP request ─────────────────────────────────────────────────
\node[single arrow, single arrow head extend=6pt,
     draw=ibmyellow, fill=ibmyellow,
     text=white, font=\sffamily\fontsize{12}{14}\selectfont\bfseries,
     minimum height=4.2cm, minimum width=1.3cm,
     inner xsep=14pt, inner ysep=0pt,
     shape border rotate=0, align=center,
     anchor=tail] at (srv.east |- 0,-1.6)
  (arrplain)
  {\parbox{2.8cm}{\centering
     {\fontsize{9}{11}\selectfont\phantom{+ transaction context}}\\[3pt]
     SOAP request\\[3pt]
     {\fontsize{9}{11}\selectfont\phantom{+ transaction context}}}};

% ── Transactional endpoint — x from arrow tip, y explicit ────────────────────
\node[rectangle, rounded corners=5pt,
     draw=ibmblue, fill=ibmblue!10,
     text width=4.6cm, minimum height=2.0cm, align=center,
     font=\sffamily\fontsize{12}{14}\selectfont,
     anchor=west] at (arrtrans.tip |- 0,1.6)
  (trans)
  {{\bfseries\color{ibmblue}Transactional Service}\\[5pt]
   {\fontsize{10}{12}\selectfont WSDL declares \texttt{<wsat:ATAssertion>}}};

% ── Non-transactional endpoint — same x as trans, y mirrored ─────────────────
\node[rectangle, rounded corners=5pt,
     draw=ibmyellow, fill=ibmyellow!10,
     text width=4.6cm, minimum height=2.0cm, align=center,
     font=\sffamily\fontsize{12}{14}\selectfont,
     anchor=west] at (arrtrans.tip |- 0,-1.6)
  (plain)
  {{\bfseries\color{ibmyellow!80!black}Non-Transactional Service}\\[5pt]
   {\fontsize{10}{12}\selectfont No WS-AT policy in WSDL}};

\end{tikzpicture}%
}% end \resizebox
\end{center}
```

::: notes
One config attribute — `propagation="conditional"` in `server.xml` — drives two outcomes automatically. When the target service declares `<wsat:ATAssertion>` in its WSDL, Liberty attaches the WS-AT coordination context and enlists it in the 2PC transaction (blue path). When the target has no WS-AT policy, the call proceeds as plain SOAP with no transaction headers (amber path). Zero application code changes required.
:::

::: instruction
This is the leave-behind slide. Pause here and invite questions before proceeding to the Externals Design section.
:::
