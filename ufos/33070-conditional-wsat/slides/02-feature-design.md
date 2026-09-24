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
  - Update client behaviour table to document the new `propagation` values and their effects
- **Target Audience**:
  - Enterprise Java developers / operations architects migrating JAX-WS workloads from tWAS to Open Liberty
  - [Java/Jakarta EE developers propagating transactions across mixed transactional/non-transactional JAX-WS endpoints]{.added}

::: notes
Enablement will be delivered through standard Open Liberty release blogs and feature documentation on openliberty.io, specifically calling out the closure of the tWAS migration gap.
:::

# Java APIs/SPIs

- **No New Public Java APIs or SPIs**:
  - Behavior is fully integrated into existing [JAX-WS / Jakarta XML Web Services]{.added} runtime and `wsAtomicTransaction-1.2` feature internals
- [**Standard JAX-WS Programming Model Preserved**:]{.deleted} [**Standard JAX-WS / Jakarta XML Web Services Programming Model Preserved**:]{.added}
  - Developers continue using standard `@WebServiceRef`, [`javax.xml.ws.Service` / `jakarta.xml.ws.Service`]{.added}, or generated JAX-WS [/ Jakarta XML Web Services]{.added} client proxies without proprietary extensions
- **Standard WS-Policy Annotations**:
  - Supports standard `@Policy` / `@PolicySets` or direct WSDL `<wsp:Policy>` / `<wsat:ATAssertion>` attachments

::: notes
No proprietary API or SPI is introduced. The feature operates transparently underneath the standard JAX-WS [/ Jakarta XML Web Services]{.added} client runtime, preserving portable Java EE / Jakarta EE code.
:::

# RESTful API Design

- **N/A — Not Applicable**:
  - This capability pertains exclusively to SOAP / JAX-WS and WS-AtomicTransaction protocols
  - No RESTful endpoints or HTTP management interfaces are introduced

::: instruction
This slide is N/A. State so briefly and move on — do not dwell.
:::

# Admin / Config / Command Line

- **New Metatype Attribute on `<wsAtomicTransaction>`**:
  - `propagation="always|conditional|never"` (Default: `always`)
- **Configuration Modes**:
  - **Zero-Migration Default**: `<wsAtomicTransaction/>` (`propagation="always"`)
  - **Opt-In Conditional Mode**:

::: changed
    `<wsAtomicTransaction propagation="conditional"/>`
:::
  - **Outbound Suppression Mode**: `<wsAtomicTransaction propagation="never"/>`
- **Lifecycle Support**: Compatible with `server pause` and `server resume`

::: notes
The propagation attribute is added to com.ibm.ws.wsat OCD with a default of always in metatype.xml and defaultInstances.xml, guaranteeing zero-migration impact.
:::

# Developer Experience

- **Frictionless Local Development**:
  - Seamless operation within Open Liberty Dev Mode (`mvn liberty:dev` / `gradle libertyDev`)
- **First-Class Tooling Support**:
  - Works out of the box with Eclipse, IntelliJ IDEA, and VS Code using standard WSDL/JAX-WS tooling
- **Automated Policy Resolution**:
  - When `propagation="conditional"`, client proxies automatically evaluate target WSDL policies

::: notes
Developers experience no friction during iterative development. JAX-WS clients resolve endpoint WSDL assertions locally and in dev mode identically to production deployments.
:::

# Deprecation & Stabilization

- **No Features Stabilized or Deprecated**:
  - `wsAtomicTransaction-1.2` remains fully supported and active
- **Compatibility with Existing Applications**:
  - Applications relying on legacy unconditional propagation remain 100% unaffected by default
  - Modernized applications opting into `propagation="conditional"` eliminate manual suspend/resume workarounds

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
