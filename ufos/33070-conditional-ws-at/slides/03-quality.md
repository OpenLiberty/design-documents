# Quality Assurance {.unnumbered}

```{=latex}
\sectionslide{Quality Assurance}
```

::: notes
This section details quality, test strategy, security posture, performance expectations, and migration impact for Conditional WS-AT.
:::

# Open Source Software

- **Uses Existing Open Liberty Dependencies**:
  - Utilizes existing **Apache CXF** and **Apache Neethi** policy engine libraries already present in Open Liberty
  - No net new third-party libraries or open-source dependencies introduced
- **Dependency Health & Compliance**:
  - Apache CXF and Neethi are mature, actively maintained ASF projects with rigorous vulnerability triage adhering to IBM security guidelines

::: notes
No net new open source dependencies are introduced. The implementation integrates directly with Liberty's existing Apache CXF / Neethi WS-Policy runtime.

**Apache CXF** is an open-source services framework that implements JAX-WS, JAX-RS, and related web services standards. Open Liberty uses it as the underlying engine for all SOAP/JAX-WS request processing, including the outbound client interceptor chain where WS-AT headers are injected or suppressed.

**Apache Neethi** is the WS-Policy engine used by CXF. It parses, evaluates, and intersects policy assertions — including `<wsat:ATAssertion>` — from WSDL documents. The check_wsdl propagation feature relies on Neethi to determine at runtime whether a target endpoint has declared a WS-AT policy requirement.
:::

# Beta & Feature Delivery

- **Beta Shielding Strategy**:
  - Configuration attribute `propagation` added to existing `<wsAtomicTransaction>` element
  - Attribute marked `ibm:beta="true"` in `metatype.xml` during beta cycle if required prior to GA promotion
  - [Internal feature `com.ibm.ws.wsat.internal` provides stable internal runtime for T-Rex beta cycles]{.added}
- **Continuous Integration**:
  - Automated FAT verification enabled on daily build pipelines

::: notes
Delivered within the wsAtomicTransaction-1.2 feature envelope and the internal com.ibm.ws.wsat.internal feature. Gated safely across beta and internal milestone builds before GA enablement.
:::

# Automated Testing

- **Dedicated FAT Bucket**:
  - Validated using `com.ibm.ws.wsat_fat.assertion` and related `wsat_fat.*` buckets
- **Key Test Scenarios**:
  - **Default Configuration (`propagation="always"`)**: Verifies legacy unconditional WS-AT context propagation behavior is preserved across both commit and rollback completions
  - **Conditional Mode (`propagation="check_wsdl"`)**:
    - Invoking endpoint with `<wsat:ATAssertion>` attaches WS-AT header and enlists in 2PC (verified via commit persistence and rollback removal)
    - Invoking endpoint without WS-AT assertions in an active transaction suppresses WS-AT header (verified by endpoint changes persisting even after client rollback)
  - [**Internal Feature Only (`com.ibm.ws.wsat.internal` via test-only feature `usr:wsatInternalTest-1.0`)**]{.added}:
    - [Verifies `propagation` attribute is rejected with configuration warning `CWWKG0032W` when only internal feature is present]{.added}
    - [Verifies outbound WS-AT propagation is completely disabled / suppressed for non-transactional endpoints across commit and rollback]{.added}
    - [Verifies endpoint with required `<wsat:ATAssertion wsp:Optional="false"/>` fails immediately with `WSATException`]{.added}
    - [Verifies inbound coordination and participant 2PC completions succeed normally under commit and rollback]{.added}
  - **Dynamic Updates**: Verifies changing `propagation` at runtime takes effect dynamically without requiring a server restart (N-01), while modifications to transport/security properties emit `CWLIB0212I` and defer until restart
  - **Indeterminate Policy Suppression (F-09)**:
    - Verifies that in `check_wsdl` mode, a call made via a dynamic `Dispatch` client (no WSDL), or to an endpoint whose CXF `Endpoint` / `EffectivePolicy` is absent, suppresses WS-AT context headers and proceeds as plain SOAP

::: notes
Test coverage verifies legacy default propagation, check_wsdl mode with positive/suppression paths, dynamic propagation switching without restart, dynamic configuration deferral for immutable attributes (CWLIB0212I emitted, active config unchanged, restart required), and indeterminate policy suppression paths for dynamic Dispatch and missing EffectivePolicy cases.
:::

# System Test Impact

- **System Test Engagement**:
  - Standard enterprise system test validation for transaction processing and JAX-WS interoperability
- **NEST (Never Ending System Test)**:
  - Add long-running multi-service orchestration scenarios featuring mixed transactional and non-transactional endpoints to NEST test suites to prevent regression

::: notes
Mixed-endpoint integration tests should be added to continuous system test runs (NEST) to validate long-term stability and prevent regressions.
:::

# Performance

- **Negligible Overhead**:
  - Simple enum/state check on `propagation` in interceptor path
  - Policy evaluation uses the cached `AssertionInfoMap` within CXF client interceptor chains
- **Zero Impact on Baseline Footprint**:
  - 0% increase in server startup time, memory footprint, or disk install size
  - Outbound SOAP throughput remains unchanged

::: notes
Performance impact is negligible since CXF caches effective endpoint policies upon client proxy initialization. No runtime I/O is introduced.
:::

# Platform / Cloud Considerations

- **Full Cross-Platform Support**:
  - Runs uniformly across all supported Open Liberty operating systems: Linux (x86_64, ppc64le, s390x), macOS, Windows, and z/OS
  - [Compatible with the same Java SE runtimes supported by the underlying JAX-WS / Jakarta XML Web Services features (Java SE 8+, subject to the feature's platform matrix)]{.added}
- **Cloud & Container Ready**:
  - Stateless outbound evaluation excels in Kubernetes, Red Hat OpenShift, and containerized microservice architectures
- [**Equal support for JAX-WS and Jakarta XML Web Services** across all supported Java SE versions]{.added}

::: notes
Operates identically across all supported OS platforms and Java LTS levels, with complete container and cloud platform portability.
:::

# Security

- **Secure Context Propagation**:
  - WS-AT coordination contexts contain transient transaction identifiers only; no sensitive user credentials or PII transmitted
  - Fully compatible with WS-Security (`ws-security-1.1`), TLS encryption, and secure SOAP envelopes
- **Context Leakage Prevention**:
  - Setting `propagation="check_wsdl"` prevents unintended transaction coordination headers from being dispatched to untrusted external endpoints

::: notes
Security is strengthened by preventing unintentional leaking of internal transaction coordination contexts to third-party or untrusted external endpoints.
:::

# Serviceability

- **Clear Diagnostic Trace**:
  - Comprehensive trace logging under `com.ibm.ws.wsat.*=all` records policy evaluation decisions (propagated vs. suppressed) and active configuration
- **Actionable Error Messages**:
  - Informative logging and FFDC capture if a remote endpoint rejects coordination or policy mismatch occurs
- **First-Failure Data Capture (FFDC)**:
  - Clean error capture for unexpected network or transport faults during 2PC coordination
- **Dynamic Configuration Handling (N-01)**:
  - Dynamic updates to `propagation` and `asyncResponseTimeout` take effect immediately on active instances without requiring a server restart
  - When transport or security properties (`sslEnabled`, `sslRef`, `externalURLPrefix`, `clientAuth`, `virtualHostRef`) are updated at runtime, `WSATConfigServiceImpl#modified()` retains the existing active configuration unchanged and emits `CWLIB0212I` to inform the operator that those changes require a server restart
  - DS component recycling — and the transient service dropouts it causes — is prevented by the `@Modified` callback absorbing the config change notification without deactivating/reactivating the component

::: notes
Serviceability provides clear trace entries indicating whether WS-AT was enabled or bypassed based on target endpoint WSDL policy.
Dynamic configuration handling (N-01): WSATConfigServiceImpl.modified() is annotated @Modified to intercept DS config-change callbacks. Changes to propagation and asyncResponseTimeout take effect immediately. On runtime server.xml updates that change transport/security properties, it logs CWLIB0212I and preserves the active transport configuration until a server restart.
:::

# InstantOn

::: changed
- **Potentially InstantOn Compatible**:
  - WS-AT policy resolution structures are stateless per endpoint, but WS-AT is not currently supported in InstantOn; this feature would be compatible with InstantOn checkpoint/restore cycles if/when WS-AT support is added
- **Dynamic Configuration Tolerance**:
  - Dynamic updates to `propagation` take effect immediately on subsequent outbound requests without application restarts
:::

::: notes
The feature establishes no static state that conflicts with InstantOn. However, WS-AT itself is not yet supported in InstantOn (on the backlog). The propagation attribute and policy resolution logic are designed to be compatible with InstantOn checkpoint/restore once WS-AT is ported.
:::


# Accessibility Compliance

- **N/A — No User Interface**:
  - This feature is a backend transaction coordination and SOAP protocol enhancement
  - Contains no graphical, web, or console user interfaces requiring WCAG / Section 508 accessibility compliance

::: notes
This slide is marked N/A as Conditional WS-AT is strictly a backend runtime capability with no visual UI components.
:::

# Migration Impact

::: changed
- **Zero-Migration Cost**: Default (`propagation="always"`) is 100% compatible with existing Liberty deployments — no `server.xml` or application changes required
- **Zero-Friction from tWAS**: `propagation="check_wsdl"` restores tWAS-style per-endpoint isolation without code changes
- **MoRE recommendation**: set `propagation="check_wsdl"` when migrating from tWAS — most closely mirrors tWAS's opt-in propagation model
- **Configuration**:
  ```xml
  <featureManager><feature>wsAtomicTransaction-1.2</feature></featureManager>
  <wsAtomicTransaction propagation="check_wsdl"/>
  ```
:::

::: notes
Provides a major migration win by allowing legacy tWAS workloads using mixed transactional/non-transactional web services to run on Liberty without application code refactoring.
:::

# End of UFO {.unnumbered}

```{=latex}
\sectionslide{End of UFO}
```
