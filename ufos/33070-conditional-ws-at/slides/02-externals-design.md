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

::: changed
- **Open Liberty Documentation**:
  - Update `wsAtomicTransaction-1.2` feature doc with configuration examples and WSDL policy discovery details
  - Update client behaviour table with the new `propagation` values and their effects
- **Target Audience**:
  - Enterprise Java developers and architects migrating JAX-WS workloads from tWAS to Open Liberty
  - [Developers needing selective transaction propagation across]{.added} [mixed transactional/non-transactional endpoints]{.added}
:::

::: notes
Enablement will be delivered through standard Open Liberty release blogs and feature documentation on openliberty.io, specifically calling out the closure of the tWAS migration gap.
:::

# Java APIs/SPIs

- **No New Public Java APIs or SPIs**:
  - Behavior is fully integrated into existing [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} runtime and `wsAtomicTransaction-1.2` feature internals
- **Standard [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} Programming Model Preserved**:
  - Developers continue using standard `@WebServiceRef`, `javax.xml.ws.Service` [/ `jakarta.xml.ws.Service`]{.added}, or generated [JAX-WS]{.deleted} [Java API / Jakarta XML Web Services]{.added} client proxies without proprietary extensions
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
  - **Private internal features**: provide the base `<wsAtomicTransaction>` plumbing attributes. `propagation` is **accepted without a warning but silently ignored**; outbound WS-AT stays disabled
  - **Public feature (`wsAtomicTransaction-1.2`)**: supplies the `propagation="always|check_wsdl"` default (`always`); the only feature that enables outbound context injection
- **Configuration Modes**:
  - **Zero-Migration Default**: `<wsAtomicTransaction/>` (`propagation="always"`)
  - **Opt-In Conditional Mode**: `<wsAtomicTransaction propagation="check_wsdl"/>`
- **Dynamic**: applies without a restart; works with `server pause` / `resume`
- [**Outbound Suppression Mode**: `<wsAtomicTransaction propagation="never"/>`]{.deleted}
:::

::: notes
The base plumbing config lives in the internal features. The public wsAtomicTransaction-1.2 feature supplies the propagation default (always) through its own default configuration rather than the metatype, so a propagation value on a server without the public feature has been set explicitly and has no effect.

Why "silently ignored" rather than "rejected": the attribute is declared in the com.ibm.ws.wsat.common metatype, which both the internal and public features load. The config layer therefore treats it as a known attribute and does not log CWWKG0032W. The runtime then never adds the outbound interceptor unless the public feature is present. A warning for this case could be added later if operators find the silence confusing.

Dynamic configuration: WSATConfigServiceImpl reads every attribute, including propagation, in its @Modified method. Edits to server.xml are applied to the running component without recycling it, so there is no restart requirement and no warning message.
:::

# Developer Experience

- **Frictionless Local Development**:
  - Seamless operation within Open Liberty Dev Mode (`mvn liberty:dev` / `gradle libertyDev`)

::: deleted
- **First-Class Tooling Support**:
  - Works out of the box with Eclipse, IntelliJ IDEA, and VS Code using standard WSDL/JAX-WS tooling
:::

::: changed
- **Automated Policy Resolution**:
  - When `propagation="check_wsdl"`, client proxies automatically evaluate target WSDL policies
:::

::: added
- **Indeterminate Policy** (`check_wsdl` mode):
  - No WSDL, `Dispatch` without WSDL, missing `Endpoint`, or no `EffectivePolicy` → transaction **not propagated** (silent pass-through), avoiding a MustUnderstand fault
  - Failing fast instead is **not implemented**; it could become a config option
:::

::: notes
Developers experience no friction during iterative development. JAX-WS clients resolve endpoint WSDL assertions locally and in dev mode identically to production deployments.
In check_wsdl mode, any indeterminate policy outcome (no WSDL, dynamic Dispatch, missing CXF Endpoint, unresolvable EffectivePolicy) is treated the same as "no assertion": propagation is suppressed. The mustUnderstand="1" attribute on WS-AT context headers is the reason suppression is the correct safe default — faulting on indeterminate policy is not implemented but could be added as a config knob.
:::

# Deprecation & Stabilization

- **No Features Stabilized or Deprecated**:
  - `wsAtomicTransaction-1.2` remains fully supported and active

::: changed
- **Compatibility with Existing Applications**:
  - Applications relying on legacy unconditional propagation remain 100% unaffected by default
  - Modernized applications opting into `propagation="check_wsdl"` eliminate manual suspend/resume workarounds
:::

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

::: deleted
- **Fully InstantOn Compatible**
:::

::: added
- **WS-AT does not currently support InstantOn**:
  - This feature does not change that
- **No additional InstantOn considerations**:
  - `propagation` is read from Liberty configuration and applied dynamically, so it needs no special handling when a checkpointed process is restored
  - The feature holds no state of its own that would need to be unique per restored instance
:::

::: notes
WS-AT itself is not supported with InstantOn, so this feature cannot be used with it today. The point of this slide is that conditional propagation adds nothing new to the work needed to support InstantOn when WS-AT support is added: the setting is ordinary dynamic configuration, and the feature keeps no state of its own.
:::

# Versionless Features

- **N/A — Enterprise WS Feature**:
  - `wsAtomicTransaction-1.2` is a specialized enterprise transaction feature and is not packaged as part of the core Java EE / Jakarta EE or MicroProfile versionless umbrellas
- **No Versionless Conflicts**:
  - Introduces no versionless feature conflicts or toleration requirements

::: instruction
This slide is N/A. State so briefly and move on — do not dwell.
:::
