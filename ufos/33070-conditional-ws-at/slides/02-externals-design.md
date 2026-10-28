# Externals Design {.unnumbered}

```{=latex}
\sectionslide{Externals Design}
```

::: instruction
This section details how the feature is surfaced to developers, administrators, and runtime tooling, covering configuration, APIs, and runtime characteristics.
:::

# Communication

- **Open Liberty Release Blog Post**:
  - Announce the new `propagation` attribute on `<wsAtomicTransaction/>` enabling conditional WS-AT propagation
- **Open Liberty Documentation**:
  - Update `wsAtomicTransaction-1.2` feature doc with configuration examples and WSDL policy discovery details
  - Update client behaviour table with the new `propagation` values and their effects
- **Target Audience**:
  - Enterprise Java developers and architects migrating JAX-WS workloads from tWAS to Open Liberty
  - [Developers needing selective transaction propagation across]{.added} [mixed transactional/non-transactional endpoints]{.added}

::: notes
Enablement will be delivered through standard Open Liberty release blogs and feature documentation on openliberty.io, specifically calling out the closure of the tWAS migration gap.
:::

# Java APIs/SPIs

- **No New Public Java APIs or SPIs**:
  - Behavior is fully integrated into existing [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} runtime and `wsAtomicTransaction-1.2` feature internals
- **Standard [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} Programming Model Preserved**:
  - Developers continue using standard `@WebServiceRef`, `javax.xml.ws.Service` [/ `jakarta.xml.ws.Service`]{.added}, or generated [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} client proxies without proprietary extensions
:::
- **Standard WS-Policy Annotations**:
  - Supports standard `@Policy` / `@PolicySets` or direct WSDL `<wsp:Policy>` / `<wsat:ATAssertion>` attachments

::: notes
No proprietary API or SPI is introduced. The feature operates transparently underneath the standard [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} client runtime, preserving portable Java EE / Jakarta EE code.
:::

# RESTful API Design

- **N/A — Not Applicable**:
  - This capability pertains exclusively to SOAP, [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added}, and WS-AtomicTransaction protocols
  - No RESTful endpoints or HTTP management interfaces are introduced

::: instruction
This slide is N/A. State so briefly and move on — do not dwell.
:::

# Admin / Config / Command Line

::: changed
- **Feature & Config Structure**:
  - [**Internal Feature (`com.ibm.ws.wsat.internal`)**]{.added}:
    - [Exposes base `<wsAtomicTransaction>` configuration with existing plumbing attributes (`sslEnabled`, `sslRef`, `clientAuth`, `externalURLPrefix`, `asyncResponseTimeout`, `virtualHostRef`)]{.added}
    - [Does **not** expose the `propagation` attribute; outbound WS-AT is disabled]{.added}
  - [**Public Feature (`wsAtomicTransaction-1.2`)**]{.added}:
    - [Extends `com.ibm.ws.wsat.internal` and augments `<wsAtomicTransaction>` with `propagation="always|check_wsdl"` (Default: `always`)]{.added}
    - [Wires in the outbound transaction context injection interceptors]{.added}
- **Configuration Modes**:
  - **Zero-Migration Default**: `<wsAtomicTransaction/>` (`propagation="always"`)
  - **Opt-In Conditional Mode**: `<wsAtomicTransaction propagation="check_wsdl"/>`
- **Lifecycle Support**: Compatible with `server pause` and `server resume`
:::

::: notes
The rebundled structure separates base plumbing config (in the internal feature) from outbound propagation controls (in the public feature). When public wsAtomicTransaction-1.2 is installed, propagation defaults to always in metatype.xml/defaultInstances.xml for zero-migration compatibility.

**Dynamic configuration (N-01):** `WSATConfigServiceImpl` implements `@Modified` so that runtime `server.xml` edits do **not** recycle the DS component. Dynamic updates to `propagation` and `asyncResponseTimeout` take effect immediately on active instances without requiring a server restart. For transport and security properties (`sslEnabled`, `sslRef`, `externalURLPrefix`, `clientAuth`, `virtualHostRef`), the active configuration is retained unchanged, informational message `CWLIB0212I` is emitted, and changes are deferred until server restart. This eliminates transient service dropouts caused by DS component teardown/re-registration during live updates.
:::

# Developer Experience

- **Frictionless Local Development**:
  - Seamless operation within Open Liberty Dev Mode (`mvn liberty:dev` / `gradle libertyDev`)
- **First-Class Tooling Support**:
  - Works out of the box with Eclipse, IntelliJ IDEA, and VS Code using standard WSDL/JAX-WS tooling
- **Automated Policy Resolution**:
  - When `propagation="check_wsdl"`, client proxies automatically evaluate target WSDL policies
- **Behaviour on Indeterminate Policy** (`check_wsdl` mode):
  - If the target endpoint WSDL is unavailable, the client is a dynamic `Dispatch` without WSDL, the CXF `Endpoint` is absent from the exchange, or no `EffectivePolicy` can be resolved — the transaction is **not propagated** (silent pass-through)
  - Root cause: outbound WS-AT headers carry `soapenv:mustUnderstand="1"`; sending them to an endpoint that does not implement WS-AT causes a SOAP MustUnderstand fault — suppression prevents this
  - The alternative — failing fast with an error on indeterminate policy — is **not implemented**; it could be added as a configuration option if a future use case requires it

::: notes
Developers experience no friction during iterative development. JAX-WS clients resolve endpoint WSDL assertions locally and in dev mode identically to production deployments.
In check_wsdl mode, any indeterminate policy outcome (no WSDL, dynamic Dispatch, missing CXF Endpoint, unresolvable EffectivePolicy) is treated the same as "no assertion": propagation is suppressed. The mustUnderstand="1" attribute on WS-AT context headers is the reason suppression is the correct safe default — faulting on indeterminate policy is not implemented but could be added as a config knob.
:::

# Deprecation & Stabilization

- **No Features Stabilized or Deprecated**:
  - `wsAtomicTransaction-1.2` remains fully supported and active
- **Compatibility with Existing Applications**:
  - Applications relying on legacy unconditional propagation remain 100% unaffected by default
  - Modernized applications opting into `propagation="check_wsdl"` eliminate manual suspend/resume workarounds

::: notes
This is an enhancement to the existing wsAtomicTransaction-1.2 feature that preserves backward compatibility while eliminating the failure mode on non-transactional endpoints.
:::

# Monitoring

- **Runtime Trace Components**:
  - Detailed diagnostic tracing available under:
    - `com.ibm.ws.wsat.*=all`
    - `org.apache.cxf.ws.policy.*=all`
- **Liberty Request Probes & FFDC**:
  - Normal transaction lifecycle metrics captured via standard Transaction Manager PMI / Introspector metrics
  - Trace logs capture configuration mode (`propagation`) and policy decision per request

::: notes
Problem determination is facilitated through existing WS-AT and CXF policy trace components. No new PMI counters are necessary as standard transaction metrics apply.
:::

# InstantOn

- **Fully InstantOn Compatible**:
  - WS-AT policy resolution structures are stateless per endpoint and support InstantOn checkpoint/restore cycles
- **Dynamic Configuration Tolerance**:
  - Dynamic updates to `propagation` take effect immediately on subsequent outbound requests without application restarts

::: notes
The feature establishes no static state that conflicts with InstantOn. Interceptor chains and WS-Policy maps are safely rebuilt and evaluated during active request dispatch.
:::

# Versionless Features

- **N/A — Enterprise WS Feature**:
  - `wsAtomicTransaction-1.2` is a specialized enterprise transaction feature and is not packaged as part of the core Java EE / Jakarta EE or MicroProfile versionless umbrellas
- **No Versionless Conflicts**:
  - Introduces no versionless feature conflicts or toleration requirements

::: instruction
This slide is N/A. State so briefly and move on — do not dwell.
:::
