# Table Examples {.unnumbered}

```{=latex}
\sectionslide{Table Examples}
```

# Ex 1: Basic two-column table

Plain Markdown pipe table — left-aligned columns, no explicit width needed.

| Setting       | Effect                                              |
|:--------------|:----------------------------------------------------|
| `always`      | Gizmo header attached to every outbound request     |
| `conditional` | Gizmo header attached only when target descriptor declares `GizmoSupport` |
| `never`       | Gizmo header never attached on outbound requests    |

::: notes
The simplest table: two columns, left-aligned, with inline code in cells.
table-filter.lua converts this to a natural-width \tabular centred on the slide.
No column widths need to be specified in the Markdown — the table is only as
wide as its content.
:::

# Ex 2: Centre-aligned columns

Use `:---:` separator syntax to centre a column. Useful for status or flag columns.

| Feature           | Version 1.x | Version 2.x |
|:-----------------:|:-----------:|:-----------:|
| `acme-gizmo`      | ✓           | ✓           |
| `acme-doodad`     | ✓           | —           |
| `acme-widget`     | —           | ✓           |
| `acme-gadget`     | ✓           | —           |
| `acme-thingamajig`| —           | ✓           |

::: notes
Example 2: three columns — left, centre, centre. Unicode tick/dash characters
render fine through pandoc.write. The table is still naturally sized.
:::

# Ex 3: Mixed alignment

Left for labels, centre for a status flag, right-aligned for a numeric column.

| Component             | Status   | Lines changed |
|:----------------------|:--------:|--------------:|
| `GizmoInterceptor`    | Modified |            47 |
| `PropagationMode`     | New      |            23 |
| `metatype.xml`        | Modified |             8 |
| `defaultInstances.xml`| Modified |             3 |
| **Total**             |          |        **81** |

::: notes
Example 3: mixed alignment — l / c / r. Bold markup in cells works because
cell content is rendered through pandoc.write, which handles Pandoc's Strong
inline correctly.
:::

# Ex 4: Table in a changed block

Use `::: changed` to mark a table as revised. The margin changebar appears
alongside the table just as it would with a bullet list.

::: changed
| Mode          | Default? | Zero-migration? | Code change required? |
|:--------------|:--------:|:---------------:|:---------------------:|
| `always`      | ✓        | ✓               | —                     |
| `conditional` | —        | —               | —                     |
| `never`       | —        | —               | —                     |
:::

::: notes
Example 4: ::: changed wrapping a table. The \cbstart{}/\cbend{} block-level
changebar fires around the tabular just as it would around a bullet list.
:::

# Ex 5: Two tables on one slide

Use blank lines between tables to place them sequentially. Each gets its own
alternating row shading and is independently centred.

**Active context**

| Gizmo config  | Target descriptor `GizmoSupport`? | Outcome                           |
|:-------------:|:---------------------------------:|:----------------------------------|
| `always`      | —                                 | transmit request + gizmo header   |
| `conditional` | yes (optional or required)        | transmit request + gizmo header   |
| `conditional` | no                                | transmit plain request            |
| `never`       | —                                 | transmit plain request            |

**No active context**

| Target descriptor `GizmoSupport`? | Outcome                    |
|:---------------------------------:|:---------------------------|
| yes (required)                    | throw `GizmoException`     |
| yes (optional) or no              | transmit plain request     |

::: notes
Example 5: two tables on one slide separated by bold headings. Each table is
independently sized and centred. This is the typical pattern for a dispatch
decision table showing active vs. inactive context cases.
:::
