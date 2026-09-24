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

**Apache Neethi** is the WS-Policy engine used by CXF. It parses, evaluates, and intersects policy assertions — including `<wsat:ATAssertion>` — from WSDL documents. The conditional propagation feature relies on Neethi to determine at runtime whether a target endpoint has declared a WS-AT policy requirement.
:::

# Beta & Feature Delivery

- **Beta Shielding Strategy**:
  - Configuration attribute `propagation` added to existing `<wsAtomicTransaction>` element
  - Attribute marked `ibm:beta="true"` in `metatype.xml` during beta cycle if required prior to GA promotion
- **Continuous Integration**:
  - Automated FAT verification enabled on daily build pipelines

::: notes
Delivered within the wsAtomicTransaction-1.2 feature envelope. Gated safely across beta and internal milestone builds before GA enablement.
:::

# Automated Testing

- **Dedicated FAT Bucket**:
  - Validated using `com.ibm.ws.wsat_fat.assertion` and related `wsat_fat.*` buckets
- **Key Test Scenarios**:
  - **Default Configuration (`propagation="always"`)**: Verifies legacy unconditional WS-AT context propagation behavior is preserved
  - **Conditional Mode (`propagation="conditional"`)**:
    - Invoking endpoint with `<wsat:ATAssertion>` attaches WS-AT header and enlists in 2PC
    - Invoking endpoint without WS-AT assertions in an active transaction suppresses WS-AT header
  - **Suppression Mode (`propagation="never"`)**: Verifies outbound WS-AT headers are never attached
  - **Dynamic Updates**: Verifies changing `propagation` dynamically updates outbound behavior without server restart

::: notes
Test coverage verifies legacy default propagation, conditional mode with positive/suppression paths, suppression mode, and dynamic configuration update paths.
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

::: changed
- **Equal support for JAX-WS and Jakarta XML Web Services** across all supported Java SE versions
:::

::: notes
Operates identically across all supported OS platforms and Java LTS levels, with complete container and cloud platform portability.
:::

# Security

- **Secure Context Propagation**:
  - WS-AT coordination contexts contain transient transaction identifiers only; no sensitive user credentials or PII transmitted
  - Fully compatible with WS-Security (`ws-security-1.1`), TLS encryption, and secure SOAP envelopes
- **Context Leakage Prevention**:
  - Setting `propagation="conditional"` or `"never"` prevents unintended transaction coordination headers from being dispatched to untrusted external endpoints

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

::: notes
Serviceability provides clear trace entries indicating whether WS-AT was enabled or bypassed based on target endpoint WSDL policy.
:::

::: changed
# InstantOn

- **Potentially InstantOn Compatible**:
  - WS-AT policy resolution structures are stateless per endpoint, but WS-AT is not currently supported in InstantOn; this feature would be compatible with InstantOn checkpoint/restore cycles if/when WS-AT support is added
- **Dynamic Configuration Tolerance**:
  - Dynamic updates to `propagation` take effect immediately on subsequent outbound requests without application restarts

::: notes
The feature establishes no static state that conflicts with InstantOn. However, WS-AT itself is not yet supported in InstantOn (on the backlog). The propagation attribute and policy resolution logic are designed to be compatible with InstantOn checkpoint/restore once WS-AT is ported.
:::
:::

# Accessibility Compliance

- **N/A — No User Interface**:
  - This feature is a backend transaction coordination and SOAP protocol enhancement
  - Contains no graphical, web, or console user interfaces requiring WCAG / Section 508 accessibility compliance

::: notes
This slide is marked N/A as Conditional WS-AT is strictly a backend runtime capability with no visual UI components.
:::

# Migration Impact

- **Zero-Migration Cost (Strict Compliance)**:
  - Default behavior (`propagation="always"`) is 100% byte-for-byte compatible with existing Liberty versions
  - No existing `server.xml` or application needs modification upon upgrade
- **Zero-Friction Modernization from tWAS**:
  - Setting `propagation="conditional"` restores tWAS-style endpoint isolation for mixed topologies without code changes

::: changed
  - **MoRE recommendation**: when migrating from tWAS, set `propagation="conditional"` — this most closely [matches]{.deleted} [mirrors]{.added} tWAS's opt-in, per-endpoint propagation model
:::

::: notes
Provides a major migration win by allowing legacy tWAS workloads using mixed transactional/non-transactional web services to run on Liberty without application code refactoring.
:::

# End of UFO {.unnumbered}

```{=latex}
\sectionslide{End of UFO}
```
