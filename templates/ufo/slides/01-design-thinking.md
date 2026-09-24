# Design Thinking {.unnumbered}

```{=latex}
\sectionslide{Design Thinking}
```


::: notes
This section of the UFO is intended to replicate some of the design thinking goals. It should be high level and user focused.
:::

# Technical Background

- TODO


::: notes
Describe background information that will be useful to help understand how this feature will be used or integrated into the product.  Use this slide to cover existing concepts and the Key Concepts chart to cover new material that will need documentation.
:::

# Problem Statement

- TODO


::: notes
Describe the problem to be solved. This should not focus on the technical details of the solution, but the technical problem that is being solved from a user perspective.

This slide is here to help the reviewers and your colleagues understand the problem this feature will solve.
:::

# Interested Users

- TODO


::: notes
Do not list any actual customer names or companies here.  Instead generalize what kind of users are interested.
For example, instead of "John Doe" or "Company A" write "Users that need to be able to [some task that was not feasible/difficult before that this feature will now address]"
:::

# High Level User Stories

- TODO


::: notes
Identify the user stories this feature is focusing on. More is better, but the follow-on design should identify and focus on the most important ones that feed into the Minimum Viable Product (MVP). The MVP will be defined on a later slide.

As a (role), I want to (goal) so that (business value).
:::

# As-Is

- TODO


::: notes
For each story in that will be delivered (this may go beyond the MVP, but for initial socialization only the MVP is required. If additional stories are to be delivered the UFO will need to be updated). This should focus on what someone would need to do to get this today. Note that even when adding something net new it is often possible to do it today, but the user experience won’t be good. This is to ensure people understand what the user experience would be without this feature.
:::

# To-Be

- TODO


::: notes
For each story that has an As-Is provide the To-Be flow. This will be used to determine if the story is complete, if the to-be isn’t achieved the function isn’t ready. Note that the UFO should go through each As-Is followed by the equivalent To-Be, not list all As-Is’s and then the To-Be’s.
:::

# Feature Design

- TODO


::: notes
Include as many charts as needed to depict the key design aspects of the Feature. This should be high level, pictures are more important than words.  Do not attempt to go into depth to describe the function of existing components or depth of Feature design. The focus here is to describe key aspects of design usage, additions or changes to existing components and a high level design of new components. The focus is to identify all the major components involved in this Feature and their interactions. Describe the impact or expectations this Feature will have put on those components.

Things to consider:
How does this work with all programming models such as OSGi Applications?
Are there any multi-version co-existence problems to solve?
How is High Availability achieved? How do you avoid single points of failure?
Capture any net new open source dependencies. If upgrading make sure we don’t ship multiple versions of same open source.
:::

# End User Overview

- TODO


::: notes
Provide a single slide overview of the function to be provided. The intent of this slide is for it to be used in presentations to users.

This slide should cover the 80% case in a single slide. Focus on the core intent of the feature.

This slide should be diagrammatical rather than bullet points.

Provide speaker notes to explain the picture rather than bullet points.

Advice:- This slide should be the last slide created prior to socialization.
:::
