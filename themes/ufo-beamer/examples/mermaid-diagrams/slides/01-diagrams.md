# Mermaid Diagram Types {.unnumbered}

```{=latex}
\sectionslide{Mermaid Diagram Types}
```

::: notes
All diagrams in this deck use colours exclusively from the UFO theme palette
(ufonavydark, ufoteal, cvdblue, cvdviolet, cvdgold, cvdorange, cvdmagenta).
Colour variables are resolved by the Lua filter before the diagram is sent to
mmdc — authors write \$cvdblue rather than \#648fff.
:::

# Flowchart

```mermaid
%%{init: {"theme": "base", "themeVariables": {
  "primaryColor": "$cvdblue",
  "primaryBorderColor": "$ufoteal",
  "primaryTextColor": "$ufonavydark",
  "lineColor": "$ufonavydark",
  "clusterBkg": "#f0f0ff",
  "clusterBorder": "$ufoteal"
}, "flowchart": {"curve": "stepBefore"}} }%%
flowchart LR
  A([Outbound Request]) --> B{Global context\nactive?}
  B -->|yes| C{Feature\nenabled?}
  B -->|no| F([Send plain request])
  C -->|no| F
  C -->|yes| D{propagation?}
  D -->|always| E[Attach header]
  D -->|never| F
  D -->|conditional| G{Policy\nasserted?}
  G -->|yes| E
  G -->|no| F
  E --> F
  classDef decision fill:$cvdblue,stroke:$ufoteal,color:$ufonavydark
  classDef terminal fill:$cvdviolet,stroke:$ufoteal,color:#ffffff
  class B,C,D,G decision
  class A,F terminal
```

::: notes
Flowchart with stepBefore routing. Decision nodes use \$cvdblue fill; terminal
nodes use \$cvdviolet. \$name variables are substituted by the Lua filter before
the diagram is passed to mmdc — no raw hex values appear in the source.
:::

# Swimlane Diagram

```mermaid
swimlane-beta LR
  subgraph Application
    Invoke[Invoke gizmo proxy]
    Receive[Receive response]
  end
  subgraph Runtime
    Check[Check global context]
    Decide[Evaluate propagation]
    Attach[Attach header]
    Plain[Send plain request]
  end
  subgraph RemoteEndpoint
    Process[Process request]
    Respond[Send response]
  end
  Invoke --> Check
  Check --> Decide
  Decide --> Attach
  Decide --> Plain
  Attach --> Process
  Plain --> Process
  Process --> Respond
  Respond --> Receive
```

::: notes
Native swimlane diagram using the \texttt{swimlane-beta} diagram type
(Mermaid \(\geq\)11). Each subgraph becomes a distinct horizontal lane — the
lane boundaries show which actor owns each activity. Cross-lane arrows show
handoffs between actors. This is a fundamentally different concept from a
flowchart: ownership of activities is the primary information, not decision
logic.
:::

# Subgraph Layout (per-lane CSS)

```mermaid
%%{init: {"theme": "base", "themeVariables": {
  "primaryColor": "$cvdblue",
  "primaryBorderColor": "$ufoteal",
  "primaryTextColor": "$ufonavydark",
  "lineColor": "$ufonavydark",
  "clusterBkg": "transparent",
  "clusterBorder": "$ufoteal"
}} }%%
%% @css #my-svg-app > rect     { fill: #e8f4ff !important; stroke: $cvdblue   !important; stroke-width:2px !important; }
%% @css #my-svg-runtime > rect { fill: #f0edff !important; stroke: $cvdviolet !important; stroke-width:2px !important; }
%% @css #my-svg-remote > rect  { fill: #fff8e8 !important; stroke: $cvdgold   !important; stroke-width:2px !important; }
flowchart LR
  subgraph app ["Application"]
    A([Call gizmo\nproxy])
  end
  subgraph runtime ["Runtime: Interceptor Chain"]
    B{Global context\nactive?}
    C{propagation\nsetting?}
    D{Policy\nasserted?}
    E[Attach header]
    F[Send plain\nrequest]
    E ~~~ F
  end
  subgraph remote ["Remote Endpoint"]
    H([Process\nrequest])
  end
  A --> B
  B -->|no| F
  B -->|yes| C
  C -->|always| E
  C -->|never| F
  C -->|conditional| D
  D -->|yes| E
  D -->|no| F
  E --> H
  F --> H
  classDef dec fill:$cvdblue,stroke:$ufoteal,color:$ufonavydark
  class B,C,D dec
```

::: notes
Flowchart with subgraphs used as visual grouping zones — a common pattern
for showing which system owns which nodes. Per-lane background colours and
borders are applied via \%\% \@css annotations: the Lua filter writes them
to a temp CSS file and passes \texttt{-C cssfile} to mmdc. SVG subgraph
element IDs follow the pattern \texttt{\#my-svg-\{subgraph-id\} > rect}.
Note: this is not a true swimlane — it is a flowchart with grouped regions.
:::

# Use Case Diagram

```mermaid
flowchart LR
  subgraph sys ["Gizmo Propagation Feature"]
    uc1(["Propagate\nconditionally"])
    uc2(["Suppress all\noutbound headers"])
    uc3(["Preserve legacy\nunconditional mode"])
    uc4(["Detect policy\nin target descriptor"])
    uc1 -.->|includes| uc4
  end
  dev(["👤 Developer"])
  admin(["👤 Administrator"])
  migrator(["👤 Migration Engineer"])
  dev --> uc1
  dev --> uc3
  admin --> uc2
  migrator --> uc3
  migrator --> uc1
  classDef actor fill:#ffffff,stroke:$ufoteal,stroke-width:1.5px
  classDef uc fill:$cvdblue,stroke:$ufoteal,color:$ufonavydark,stroke-width:1.5px
  classDef support fill:$cvdviolet,stroke:$ufoteal,color:#ffffff
  class dev,admin,migrator actor
  class uc1,uc2,uc3 uc
  class uc4 support
```

::: notes
Use case diagram using Mermaid flowchart LR. Actors are plain white rounded
rectangles outside the system boundary subgraph. Primary use cases are
\$cvdblue; supporting use cases (included) are \$cvdviolet. The dashed include
relationship uses Mermaid's native dotted arrow syntax.
:::

# Class Diagram

```mermaid
classDiagram
  class GizmoConfig {
    +PropagationMode propagation
    +configure()
  }
  class PropagationMode {
    <<enumeration>>
    ALWAYS
    CONDITIONAL
    NEVER
  }
  class OutboundInterceptor {
    +handleMessage(Message)
    -evaluatePolicy(Endpoint) bool
  }
  class PolicyMap {
    +get(QName) Collection~PolicyInfo~
  }
  class GizmoAssertion {
    +isOptional() bool
  }
  GizmoConfig --> PropagationMode : uses
  OutboundInterceptor --> GizmoConfig : reads
  OutboundInterceptor --> PolicyMap : queries
  PolicyMap --> GizmoAssertion : contains
  style GizmoConfig fill:$cvdblue,stroke:$ufoteal,color:$ufonavydark
  style OutboundInterceptor fill:$cvdviolet,stroke:$ufoteal,color:#ffffff
  style PropagationMode fill:$cvdgold,stroke:$ufoteal,color:$ufonavydark
  style PolicyMap fill:$cvdorange,stroke:$ufoteal,color:#ffffff
  style GizmoAssertion fill:$cvdmagenta,stroke:$ufoteal,color:#ffffff
```

::: notes
Class diagram showing the five key classes involved in conditional gizmo
propagation. Each class uses a distinct CVD-safe palette colour — all five
categorical slots are used here to demonstrate the full palette.
:::

# Sequence Diagram

```mermaid
sequenceDiagram
  participant App as Application
  participant IC as Outbound Interceptor
  participant PE as Policy Engine
  participant EP as Remote Endpoint

  App->>IC: invoke gizmo proxy
  IC->>IC: read propagation setting
  alt propagation = conditional
    IC->>PE: getAssertions(GizmoAssertion, endpoint)
    PE-->>IC: assertions present?
    alt assertion present
      IC->>EP: request + coordination header
    else no assertion
      IC->>EP: plain request (no header)
    end
  else propagation = always
    IC->>EP: request + coordination header
  else propagation = never
    IC->>EP: plain request (no header)
  end
  EP-->>App: response
```

::: notes
Sequence diagram showing the interceptor chain decision for the three
propagation modes. The default themeVariables init block applies \$cvdblue
actor backgrounds and \$ufoteal borders automatically — no explicit classDef
needed in sequence diagrams.
:::

# State Diagram

```mermaid
stateDiagram-v2
  [*] --> Disabled
  Disabled --> Always : enable feature
  Always --> Conditional : propagation="conditional"
  Always --> Never : propagation="never"
  Conditional --> Always : propagation="always"
  Conditional --> Never : propagation="never"
  Never --> Always : propagation="always"
  Never --> Conditional : propagation="conditional"
  Always --> Disabled : remove feature
  Conditional --> Disabled : remove feature
  Never --> Disabled : remove feature
```

::: notes
State diagram showing the propagation mode state machine. The three active
states (Always, Conditional, Never) each represent a distinct outbound
behaviour. Default themeVariables supply the palette colours.
:::

# Timeline Diagram

```mermaid
timeline
  title Outbound Request Lifecycle
  section Context Created
    begin() called : Global coordination context established
  section Outbound Call
    Gizmo proxy invoked : Application calls remote service
  section Interceptor Chain
    OutboundInterceptor fires : Reads propagation config
    Policy engine consulted : Checks descriptor for assertion
  section Header Decision
    Header attached : always, or conditional + assertion present
    Header suppressed : never, or conditional + no assertion
  section Coordination
    Context registered : Coordinator tracks participant
    Commit or rollback : Transaction completes
```

::: notes
Timeline event modelling diagram showing the lifecycle of an outbound
request from context creation through coordination completion. The timeline
type uses cScale0-4 for section colours — these are set to the CVD palette
by the default themeVariables init block.
:::

# Architecture Diagram

```mermaid
graph TB
  subgraph App ["Application Layer"]
    GZ["Gizmo Client\nProxy"]
  end
  subgraph Runtime ["Runtime"]
    IC["Outbound\nInterceptor"]
    CFG["Gizmo\nConfig"]
    POL["Policy\nEngine"]
    COORD["Coordination\nService"]
  end
  subgraph Remote ["Remote Service"]
    EP["Gizmo Endpoint"]
    DESC["Policy\nDescriptor"]
  end
  GZ --> IC
  IC --> CFG
  IC --> POL
  POL --> DESC
  IC -->|"attach header"| COORD
  COORD -->|"CoordinationContext"| EP
  IC -->|"plain request"| EP
  classDef appLayer     fill:$cvdblue,stroke:$ufoteal,color:$ufonavydark
  classDef runtimeLayer fill:$cvdviolet,stroke:$ufoteal,color:#ffffff
  classDef remoteLayer  fill:$cvdgold,stroke:$ufoteal,color:$ufonavydark
  class GZ appLayer
  class IC,CFG,POL,COORD runtimeLayer
  class EP,DESC remoteLayer
```

::: notes
C4-style component architecture diagram using graph TB with subgraphs as
layers. Application, runtime, and remote service layers use three distinct
CVD palette colours (\$cvdblue, \$cvdviolet, \$cvdgold) so they are
distinguishable in greyscale and under all common CVD types.
:::

# Packet Diagram

```mermaid
packet-beta
  0-31: "Magic: GIZMO (0x47 49 5A 4D)"
  32-39: "Version Major (1)"
  40-47: "Version Minor (0)"
  48-55: "Flags (ByteOrder | Fragment)"
  56-63: "MsgType: Request (0)"
  64-95: "MessageSize (uint32)"
  96-127: "RequestId (uint32)"
  128-135: "ResponseExpected (bool)"
  136-159: "Reserved[3]"
  160-191: "TargetKey Length (uint32)"
  192-255: "TargetKey (variable)"
  256-287: "Operation Length (uint32)"
  288-351: "Operation String (variable)"
  352-383: "ServiceContext List (coordination header injected here)"
  384-415: "Request Body (marshalled args)"
```

::: notes
Packet diagram showing a fictional GIZMO 1.0 request message format. The
coordination header is injected into the ServiceContext list (bytes 352-383)
by the OutboundInterceptor when propagation conditions are met.
The packet-beta diagram type requires Mermaid \geq 11.0 (mmdc \geq 12.0).
:::
