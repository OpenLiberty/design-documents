# Design Thinking {.unnumbered}

```{=latex}
\sectionslide{Design Thinking}
```

::: instruction
This section establishes the user-centric motivation, target personas, migration hurdles, and target architecture for Conditional WS-AT.
:::

# Technical Background

- **WS-AtomicTransaction (WS-AT)** provides two-phase commit transaction coordination across distributed web services

::: changed
- In **tWAS**:
  - Administrator-configured policy sets and bindings control WS-AT propagation per web service / endpoint
- In **Open Liberty**:
  - Outbound WS-AT is governed by `wsAtomicTransaction-1.2` and configured via `<wsAtomicTransaction/>`
  - Unconditional propagation is the legacy behavior and the default (`propagation="always"`)
  - Compatible with [**JAX-WS 2.2** (`javax.xml.ws.*`)]{.added} [and **Jakarta XML Web Services 3.0+** (`jakarta.xml.ws.*`)]{.added}
  - Private internal WS-AT features (e.g. T-Rex) do not propagate WS-AT context outbound
:::

::: notes
WS-AT coordinates distributed transactions across JAX-WS and Jakarta XML Web Services endpoints. In tWAS the decision is configured per service / endpoint through policy sets. Open Liberty's wsAtomicTransaction-1.2 feature historically operated globally across all JAX-WS / Jakarta XML Web Services outbound calls. The new `check_wsdl` mode keeps that server-wide scope but lets the target's WSDL policy decide per request; see Migration Impact for the differences from tWAS.

The private internal features (`io.openliberty.wsAtomicTransaction1.2.internal.*`) provide the WS-AT runtime for internal consumers such as T-Rex. The public feature supplies the `propagation="always"` default through its own default configuration.
:::

# Problem Statement

- Enabling `wsAtomicTransaction-1.2` causes WS-AT context to propagate on **all outbound requests** in a global transaction, even if the target lacks WS-AT assertions
- Calls to non-transactional / 3rd-party services fail when WS-AT headers are rejected

::: deleted
- **Desired outcome**: Allow transactions to be propagated to only those web services that express a WS-AT policy assertion in their WSDL:
  ```xml
  <wsp:Policy wsu:Id="WSAT_Policy">
      <wsat:ATAssertion wsp:Optional="false"/>
  </wsp:Policy>
  ```
- Retain unconditional propagation as the default for zero-migration compatibility
:::

::: notes
Unconditional propagation breaks communication with non-transactional downstream services when an active JTA transaction exists.

XML namespace prefixes used in the WSDL snippet:
- wsp: WS-Policy namespace (http://schemas.xmlsoap.org/ws/2004/09/policy or http://www.w3.org/ns/ws-policy), defining policy containers and assertion attributes like wsp:Optional.
- wsu: WS-Security Utility namespace (http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd), providing the wsu:Id attribute used to identify and attach policy elements.
- wsat: WS-AtomicTransaction namespace (http://docs.oasis-open.org/ws-tx/wsat/2006/06), specifying the ATAssertion element.
:::

# Interested Users

- **Enterprise Application Developers** migrating JAX-WS applications from Traditional WebSphere (tWAS) to Open Liberty
- **Integration Architects** designing composite enterprise workflows where transactional operations coexist with non-transactional external APIs (e.g., payment gateways, audit logging, notification services)


::: changed
- **DevOps & Platform Teams** seeking a zero-code-change way to call a mix of transactional and non-transactional services (see Migration Impact for how this differs from tWAS policy sets)
:::

::: added
- **Internal Liberty Frameworks & Subsystems (e.g. T-Rex)** requiring WS-AT protocol infrastructure without exposing outbound propagation, or the `propagation` setting, to users
:::

::: notes
Target users are primarily enterprise modernization teams moving multi-tier SOAP applications to Liberty without needing to re-architect or refactor existing transactional orchestration code.
:::

# High Level User Stories

- **Zero-Migration** — `<wsAtomicTransaction propagation="always"/>`:
  - *As an existing Liberty user*, I want my current applications to behave identically without changes when upgrading Liberty, so that my existing deployment remains completely unbroken.

::: changed
- **Opt-In** — `<wsAtomicTransaction propagation="check_wsdl"/>`:
  - *As an enterprise developer*, I want WS-AT context attached only to endpoints that advertise `<wsat:ATAssertion>`, so that non-transactional services are called cleanly without manual transaction suspension.
:::

::: deleted
- **Outbound Suppression** — `<wsAtomicTransaction propagation="never"/>`
:::

::: notes
Two user stories, each tied to an explicit `<wsAtomicTransaction/>` configuration:

1. **Zero-Migration Compatibility** (`<wsAtomicTransaction/>`): No `propagation` attribute means the default of `always` applies. Existing deployments continue unconditional WS-AT propagation on all outbound calls — zero config changes required on upgrade.

2. **Opt-In Conditional Propagation** (`<wsAtomicTransaction propagation="check_wsdl"/>`): Liberty inspects the target endpoint's WSDL for a `<wsat:ATAssertion>` policy. If present, WS-AT context is attached; if absent, the call proceeds as plain SOAP. Eliminates the need for manual `TransactionManager.suspend()` / `resume()` guards around non-transactional service calls.
:::

::: instruction
Cover each story in turn; invite the room to challenge whether the default of "always" truly covers their migration use case before moving on.
:::

# As-Is: [Unconditional]{.deleted} Propagation [always on by default]{.added}

- With `wsAtomicTransaction-1.2` enabled, any outbound JAX-WS call during a JTA transaction injects WS-AT headers
- Non-transactional / 3rd-party endpoints reject unknown headers or fail schema validation
- Developers must manually modify application source code [**to stop propagation**]{.added}:
  - Explicitly obtain `TransactionManager` / `UserTransaction`
  - Suspend transaction prior to invocation, then resume afterwards
  - Handle complex failure and rollback paths manually

::: notes
Today, developers must manually wrap third-party or non-transactional web service calls in transaction suspend/resume blocks to stop propagation, increasing code complexity and introducing transaction leak risks.
:::

# To-Be: Configurable Propagation

::: changed
- **`wsAtomicTransaction-1.2` Not Enabled** *(including internal-only, e.g. T-Rex)*:
  - Plain SOAP, no outbound WS-AT headers; `propagation` accepted without warning but **silently ignored**
  - Required `<wsat:ATAssertion/>` in target WSDL: call fails with `WS-AT Feature is not installed`
- **Default Mode (`propagation="always"` or unconfigured)**:
  - Unconditional propagation remains the default (Zero-Migration)
- **Conditional Mode (`propagation="check_wsdl"` / Opt-In)**:
  - Context attached **only** if target WSDL declares `<wsat:ATAssertion/>` (required or `wsp:Optional="true"`); otherwise plain SOAP
- [**Suppression Mode (`propagation="never"`)**]{.deleted}
:::

- **Zero code changes required** for migrated applications

::: notes
With propagation="check_wsdl", Liberty inspects the endpoint policy engine. If no WS-AT assertion is declared, WS-AT headers are omitted, allowing harmonious mixed-endpoint topologies within a single transaction.

Packaging: the private internal features provide the base participant/coordination runtime and plumbing config. wsAtomicTransaction-1.2 is the only feature that enables outbound propagation and supplies the propagation default.

When only an internal WS-AT feature is present, the `propagation` attribute is declared in the shared metatype, so the config layer accepts it without a CWWKG0032W warning. It is then ignored: outbound propagation is permanently off on such a server whatever value is set. This is deliberate and is covered by InternalFeatureOnlyTest.
:::

# Feature Design: Runtime Interception

::: changed
## Active transaction

| WS-AT Config       | Target WSDL `ATAssertion`?              | Outcome                                          |
| :------------------:| :---------------------------------------:| :------------------------------------------------|
| WS-AT not enabled  | no                                      | transmit SOAP request                            |
| WS-AT not enabled  | yes (optional)                          | transmit SOAP request                            |
| WS-AT not enabled  | yes (required)                          | fail: `WS-AT Feature is not installed`           |
| `check_wsdl`      | indeterminate (no WSDL / no policy tree) | transmit SOAP request                            |
| `check_wsdl`      | no                                      | transmit SOAP request                            |
| `check_wsdl`      | yes (optional or required)              | transmit SOAP + WS-AT context                    |
| `always` (default) | —                                       | transmit SOAP + WS-AT context                    |

## No active transaction (WS-AT enabled)

| Target WSDL `ATAssertion`? | Outcome                                                                             |
|:--------------------------:|:------------------------------------------------------------------------------------|
| no                         | transmit SOAP request                                                               |
| yes (optional)             | transmit SOAP request                                                               |
| yes (required)             | fail: `Detected WS-AT policy, however there is no active transaction in current thread.` |
:::

::: notes
"WS-AT not enabled" means the public wsAtomicTransaction-1.2 feature is absent, which includes a server with only a private internal WS-AT feature. A required assertion fails with the same "WS-AT Feature is not installed" fault whether or not a transaction is active. The failure is a SOAP Fault wrapping a RuntimeException, not a WSATException.

Active transaction: if wsAtomicTransaction-1.2 is not enabled, or the target WSDL has no ATAssertion, the request proceeds as plain SOAP. Headers are only attached when the feature is active, propagation is "always" or "check_wsdl", and (for check_wsdl) the target WSDL declares ATAssertion.

Indeterminate policy (F-09): in check_wsdl mode, when the CXF Endpoint is absent from the exchange, the client is a dynamic Dispatch without WSDL, or the EffectivePolicy tree cannot be resolved, the outcome is treated identically to "no assertion" — propagation is suppressed. This is deliberate: outbound WS-AT headers carry mustUnderstand="true" and would cause a SOAP MustUnderstand fault on any non-WS-AT endpoint.

No active transaction, WS-AT enabled: ATAssertion optional or absent — plain SOAP. ATAssertion required — the call fails with a WSATException wrapped in a SOAP Fault, because there is no transaction to propagate. One-way operations cannot carry a WS-AT context; if a context would be attached to a one-way call, the call fails with "WS-AT can not work on ONE-WAY webservice method". This applies in both always and check_wsdl modes.
:::

# Architectural Rationale: `check_wsdl` Fail-Safe Contract

::: added
- **`mustUnderstand="1"` on outbound WS-AT headers**:
  - Endpoints that do not implement WS-AT **must** reject them with a SOAP MustUnderstand fault
- **Opt-in on positive evidence**:
  - Context is attached only when the target WSDL declares `<wsat:ATAssertion>`
- **Indeterminate policy → suppression**:
  - No WSDL, `Dispatch` client without WSDL, missing `Endpoint`, or no `EffectivePolicy` is treated as "no assertion"
- **`propagation="always"` as the escape hatch**:
  - Propagates regardless of WSDL availability (the default)
:::

::: notes
The mustUnderstand="1" attribute on WS-AT SOAP headers is the root cause of MustUnderstand faults on non-WS-AT endpoints — the SOAP spec requires recipients to fault on headers they do not understand when this flag is set. check_wsdl therefore uses a positive-evidence model: absent confirmed WSDL support, the safe default is suppression. Dynamic Dispatch clients, missing WSDL endpoints, and unresolvable CXF EffectivePolicy are all treated identically to "no assertion". Users who know their topology is fully transactional and do not want the WSDL lookup overhead can remain on the always default.
:::

# End User Overview

```{=latex}
% IBM Carbon 14-colour categorical palette (pairing 1, light theme)
%   #1192e8  Blue-50  (index  2) — WS-AT / transactional path
%   #b28600  Yellow-50 (index 10) — plain SOAP / suppressed path
% CVD-safe: differ in both hue and luminance across all deficiency types.
\definecolor{ibmblue}{RGB}{17,146,232}
\definecolor{ibmyellow}{RGB}{178,134,0}
\usetikzlibrary{shapes.arrows,fit}
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
   \ \ "check\_wsdl"/>};

% Change marker: this value was "conditional" in the original UFO.
\ifufochanges
\node[draw=ufochanged, line width=1.8pt, dashed,
      dash pattern=on 4pt off 2pt,
      rounded corners=6pt, fill=none,
      fit=(cfg), inner sep=4pt] {};
\fi

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
One config attribute — `propagation="check_wsdl"` in `server.xml` — drives two outcomes automatically. When the target service declares `<wsat:ATAssertion>` in its WSDL, Liberty attaches the WS-AT coordination context and enlists it in the 2PC transaction (blue path). When the target has no WS-AT policy, the call proceeds as plain SOAP with no transaction headers (amber path). Zero application code changes required.
:::

::: instruction
This is the leave-behind slide. Pause here and invite questions before proceeding to the Externals Design section.
:::
