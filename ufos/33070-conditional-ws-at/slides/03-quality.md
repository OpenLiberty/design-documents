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

::: changed
- **Beta Shielding Strategy** (two independent mechanisms):
  - **Schema visibility**: `propagation` is marked `ibm:beta="true"` in the `com.ibm.ws.wsat.common` `metatype.xml`. This only hides the attribute from the generated `server.xml` schema in non-beta builds; the runtime does not enforce it
  - **Runtime guard**: `WSATConfigServiceImpl` reads `propagation` only when `ProductInfo.getBetaEdition()` is true. In a non-beta edition the value is ignored and Liberty behaves as `always`
  - At GA, remove **both** the `ibm:beta` marker and the `getBetaEdition()` check
- **Continuous Integration**:
  - Automated FAT verification enabled on daily build pipelines
:::

::: notes
Delivered within the wsAtomicTransaction-1.2 feature envelope. The metatype marker and the runtime check are separate: removing only the marker would expose the attribute in the schema while the runtime still ignored it outside a beta edition, and removing only the runtime check would leave the attribute hidden from the schema. Both must be removed together at GA promotion.
:::

# Automated Testing

- **Dedicated FAT Bucket**:
  - Validated using `com.ibm.ws.wsat_fat.assertion` and related `wsat_fat.*` buckets

::: changed
- **Key Test Scenarios**:
  - **Default Configuration (`propagation="always"`)**: Verifies legacy unconditional WS-AT context propagation behavior is preserved across both commit and rollback completions
  - **Conditional Mode (`propagation="check_wsdl"`)**:
    - Invoking endpoint with `<wsat:ATAssertion>` attaches WS-AT header and enlists in 2PC (verified via commit persistence and rollback removal)
    - Invoking endpoint without WS-AT assertions in an active transaction suppresses WS-AT header (verified by endpoint changes persisting even after client rollback)
:::

::: deleted
- **Suppression Mode (`propagation="never"`)**
:::

::: notes
Test coverage verifies legacy default propagation and check_wsdl mode with positive and suppression paths.
:::

# Automated Testing: Other Scenarios

::: added
- **Internal Feature Only (`usr:wsatInternalTest-1.0`)**:
  - `propagation` accepted with no `CWWKG0032W` and silently ignored; outbound calls are plain SOAP and not enlisted (commit and rollback)
  - Required assertion fails with `WS-AT Feature is not installed`; optional assertion sends plain SOAP
  - Inbound request carrying a WS-AT context is rejected with the same fault
- **Invalid value**: `CWWKG0032W` reported and server falls back to `always`
- **Dynamic Updates**: `propagation` changes apply without restart in both directions and survive `server pause` / `server resume`
- **Indeterminate policy (`check_wsdl` mode)**: `Dispatch` client without WSDL and missing `Endpoint`/`EffectivePolicy` suppress WS-AT header (to be automated before GA)
:::

::: notes
Covers the internal-only feature behaviour, invalid values, dynamic switching, and indeterminate-policy suppression paths (`Dispatch` without WSDL, missing `Endpoint`/`EffectivePolicy`) in `check_wsdl` mode.
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

::: changed
- **Minimal change to outbound request cost**:
  - Policy is already looked up for each outbound request by CXF's policy interceptor and the existing WS-AT interceptor; this feature adds a read of the `propagation` setting and a comparison
  - That lookup reads policy from the CXF client's in-memory service model, not from the network
- **Minimal change to baseline footprint**:
  - Minimal change to server startup time, memory footprint, and install size
:::

::: notes
Where the policy comes from: CoorContextOutInterceptor calls WSCoorUtil.isOptional (when the AssertionInfoMap has no AT assertion), which calls the CXF PolicyEngine's getEffectiveClientRequestPolicy. CXF's own PolicyOutInterceptor makes the same call when it builds the AssertionInfoMap. CXF builds the effective policy from the policy attachments held in the client's service model (ServiceInfo, EndpointInfo and BindingOperationInfo extensors, via the ServiceModelPolicyProvider and Wsdl11AttachmentPolicyProvider), which were populated from the target WSDL when the client was created. The policy engine classes contain no network or file access. The computed effective policy is cached as a property on the BindingOperationInfo (and the endpoint policy on the EndpointInfo), so after the first call for an operation the lookup is a cache hit.

The lookup existed before this feature (it detects a required assertion with no active transaction); check_wsdl only adds a decision on its result. No performance measurements have been taken, hence the qualitative wording.
:::

# Platform / Cloud Considerations

- **Full Cross-Platform Support**:
  - Runs uniformly across all supported Open Liberty operating systems: Linux (x86_64, ppc64le, s390x), macOS, Windows, and z/OS
  - [Fully verified across IBM Semeru Runtimes and Eclipse Temurin Java SE 11, 17, and 21 LTS releases]{.deleted}
  - [Compatible with the same Java SE runtimes supported by the underlying JAX-WS / Jakarta XML Web Services features (Java SE 8+, subject to the feature's platform matrix)]{.added}
- **Cloud & Container Ready**:
  - Stateless outbound evaluation excels in Kubernetes, Red Hat OpenShift, and containerized microservice architectures
- [**Equal support for JAX-WS and Jakarta XML Web Services** across all supported Java SE versions]{.added}

::: notes
Operates identically across all supported OS platforms and Java LTS levels, with complete container and cloud platform portability.
:::

# Security

::: changed
- **No change to what is transmitted**:
  - This feature only controls *whether* the WS-AT context is sent on an outbound request, not its content or how it is protected
  - Existing WS-Security and TLS configuration applies exactly as before
- **Narrower propagation in `check_wsdl` mode**:
  - The context is sent only to endpoints whose WSDL declares a WS-AT assertion
  - The WSDL is supplied by the target, so this is a compatibility control, not an access control
:::

::: notes
The default (always) sends the context to every endpoint called inside a global transaction, as before. check_wsdl reduces the set of recipients to those that advertise WS-AT. Because the target's own WSDL decides, an endpoint that advertises WS-AT will receive the context in check_wsdl mode; do not rely on this setting to keep the context from a service you do not trust.
:::

# Serviceability

::: changed
- **Clear Diagnostic Trace**:
  - Trace under `com.ibm.ws.wsat.*=all` records policy decisions (propagated vs. suppressed) and active configuration
- **Actionable Errors and FFDC**:
  - Logging and FFDC capture if a remote endpoint rejects coordination or on transport faults during 2PC
- **Dynamic Configuration**:
  - Changes to `propagation` (and the other `<wsAtomicTransaction>` attributes) in `server.xml` are applied to the running server without a restart
  - A `propagation` value on a server without the public `wsAtomicTransaction-1.2` feature is accepted without a warning and has no effect; the trace records the value and that it is unused
:::

::: notes
Serviceability provides clear trace entries indicating whether WS-AT was enabled or bypassed based on target endpoint WSDL policy.
WSATConfigServiceImpl reads all attributes, including propagation, in its @Modified method, so server.xml edits take effect without recycling the component.
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
- **Existing Liberty users**: the default (`propagation="always"`) keeps today's behavior; no `server.xml` or application changes are required
- **Migrating from tWAS**: `check_wsdl` gives a similar result for the common case (WS-AT context goes to services that declare WS-AT and not to others) without code changes, but it is **not equivalent** to tWAS policy sets:

| | tWAS | Liberty `check_wsdl` |
|:--|:--|:--|
| Where configured | Policy sets and bindings, per service / endpoint | One server-wide attribute |
| What decides | The configured policy set | The WS-AT assertion in the **target's** WSDL |
| Override per endpoint | Yes | No |
| No WSDL (e.g. `Dispatch`) | — | Plain SOAP |
:::

::: notes
In tWAS the consumer chooses, endpoint by endpoint, through configuration. In Liberty check_wsdl the provider chooses, by advertising a WS-AT assertion in its WSDL, and the consumer has a single switch. Consequences: (1) you cannot propagate to one service that lacks an assertion while skipping another; use always to reach every service, or add the assertion to the WSDL. (2) You cannot suppress propagation to a service that does advertise WS-AT. (3) A service that supports WS-AT but does not advertise it is treated as having no assertion and is not enlisted, so its work is not rolled back with the caller's transaction. (4) Clients with no WSDL cannot be evaluated and are sent as plain SOAP. Review each migrated application's service WSDLs against these points before choosing check_wsdl. Configuration: <wsAtomicTransaction propagation="check_wsdl"/> alongside the wsAtomicTransaction-1.2 feature.
:::

# End of UFO {.unnumbered}

```{=latex}
\sectionslide{End of UFO}
```
