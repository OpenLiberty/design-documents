# Externals Design {.unnumbered}

```{=latex}
\sectionslide{Externals Design}
```

# Communication

- TODO


::: notes
How will the existence of this feature be communicated to users?  Every feature will need some form of enablement and this slide is where those considerations should be listed.

At a minimum the feature should expect to be described in the applicable beta release blog post, and the GA blog post. However depending on the feature one or more of the following should be considered:

Additional Blog post specific to the feature/functionality (openliberty.io/blogs)
Sample code demonstrating capability (for example, added to the feature example section on openliberty.io/docs Reference/Feature section, like seen in https://openliberty.io/docs/latest/reference/feature/appSecurity.html#_examples)
YouTube video demonstrating capability
Sample scripts to drive capability
Getting started guide to use feature (doc and/or video)
Communication on social media such as Twitter (note, blog posts are already always tweeted about once published)
Open Liberty guides (openliberty.io/guides).  Engaging developers and the community is important and key to our Open Liberty's strategy. Open Liberty guides are designed to take developers through a particular topic or technology in 15 or 20 mins providing meaningful learning experience to engage them.  If the feature applies to Open Liberty and is relevant to developers, consider if guides should be created to engage developers and the community.  Contact YK Chang if you need help determining if a guide is appropriate.

These might be delivered via WASdev.net, the middleware blog, the WASdev github org, openliberty.io, the OpenLiberty github org or elsewhere.

When looking at this slide you MUST identify the target audience for what is being provided and should be related into the dev/ops lifecycle.

Make sure you contact the publication venue early to ensure that it is an appropriate place to put the content; you don’t want to ask someone to publish something that is done only to discover they say no.
:::

# Java APIs/SPIs

- TODO


::: notes
Provide an initial Java API proposal for any product API or SPIs. When going through the implementation it may be discovered that the API needs to evolve, however the Java API/SPI needs to be designed with the developer who calls it in mind, rather than what is easiest for the implementation.

Include and mark any third-party APIs/SPIs that this feature provides.

New features should only expose the public APIs and functions that they actually require. They should not expose any additional public APIs and functions that happen to be used by the internal implementation.

Show how the API/SPI will be used, rather than every detail of the API. Focus on the 80% path.

For OL features, follow this naming convention for packages:
API - io.openliberty.xxx
SPI - io.openliberty.xxx.spi
Internal - io.openliberty.xxx.internal
:::

# RESTful API Design

- TODO


::: notes
If REST endpoints are being exposed by this feature you must document:
(1) What they are (URL, HTTP verbs, HTTP headers, query / form parameters, payload formats, security domain, versioning model, resource design)
(2) How they will be exposed (REST Handler, z/OS Connect, WAB, J2EE App, Http Whiteboard, etc)
The goal is to have a discussion about the types of resources being exposed and how they are being exposed. The focus is on RESTful best practices.
It is more important to focus on how the RESTful API is to be used, rather than every detail of the API. Focus on the 80% path.
:::

# Admin / Config / Command Line

- TODO


::: notes
Describe how to configure and administer this feature.  Follow the Open Liberty config design practices, less configuration is better.  Show examples of the configuration, relate back to the user stories earlier in this slide. Focus on the 80% path and minimal configuration. If the config is only required by 10% of users, do we really need it?
If the feature needs new command line utilities or script, this is where to include it.

Should any component of this feature be “Pauseable”, i.e. support being stopped and started when an administrator issues the “server pause” and “server resume” command?  The pause command is intended to allow an administrator to pause and resume portions of the application server that handle external requests; for example, all of our HTTP listeners are pauseable.  Also note that all “Pauseable” components are paused during the quiesce phase of server shutdown.

If you’re doing server.bat/server(.sh) changes, be aware the z/OS started task bypasses the script and uses other C code instead, so you should make sure you don’t also need to make changes over there.

For SSO features, make sure that any new attributes are consistent across the SSO features - SPNEGO, LTPA, OIDC,SAML,OAUTH..)
:::

# Developer Experience

- TODO


::: notes
Describe the experience of a developer using this feature. What changes are required in the developer tools for Liberty and/or tWAS? What about moving from development to deployment? How does this fit into a build/automated deploy pipeline? Are there any open source/third party packages that should integrate with this capability? Some things to consider:
Liberty Starter
Liberty's dev mode
IDEs
Eclipse
IntelliJ
VS Code
Others
Language servers
Jakarta EE
MicroProfile
Liberty configuration
Build tools
Maven (and Liberty Maven plugin)
Gradle (and Liberty Gradle plugin)
Ant
Command line
Deployment
OpenShift Pipelines
Ansible
Podman or Docker
Popular CI/CD/DevOps tools
Note to System Testers: Since you are the first consumers of the feature, if you feel the Developer Experience is lacking, that is valuable input!
:::

# Deprecation & Stabilization

- TODO


::: notes
Describe, in general details, any capabilities that will be stabilized by this feature.

Open Liberty Features can not be deprecated (only stabilized)
What is the impact to existing test applications?
:::

# Monitoring

- TODO


::: notes
How does a user monitor this feature to detect and diagnose problems.
What new PMI metrics are needed (for new pools, queues, etc. that need visibility)?
What new events does your design introduce that should be timed at runtime (Liberty request probes)?
:::

# InstantOn

- TODO


::: notes
InstantOn:

All new, public Liberty features that can be enabled by the feature manager are expected to support InstantOn.  New functionality must support InstantOn that is added to existing features that already support InstantOn. For InstantOn support the largest concern is how the feature reacts to Liberty configuration updates when restoring a running application instant.  Be sure to answer the following questions with regard to InstantOn support.  If the new functionality is not part of the Liberty runtime itself then mark this slide as N/A, for example, new command line utilities.

Does the functionality provided by this UFO support InstantOn? If not, justify why not.
Can the feature respond to dynamic updates to Liberty configuration associated with the feature?  If not, identify the configuration.
Do dynamic updates to Liberty configuration associated with the feature require applications to restart?  If so, identify the configuration.
Is there Liberty configuration associated with the feature that is typically only known at the time the application is deployed?  If so, identify the configuration.  For example, hostname, port or credentials to connect to a remote resource.
For Liberty configuration that is typically only known at the time the application is deployed, can the server tolerate being started without the configuration present?  How would the configuration be parameterized such that it can be set at deployment time?
Does the feature establish state while the server is starting or an application is starting which needs special consideration when restoring an application process into multiple running instances?  For example, a unique ID (e.g. UUID) that must be unique for each running instance of the application.
:::

# Versionless Features

- TODO


::: notes
Versionless Features:

All new Liberty features that belong to the MicroProfile or JavaEE / JakartaEE platforms are expected to support versionless features.  Answer the following questions to determine if your changes involve versionless features:

Does this feature have any effect on versionless features, or introduce a new versionless feature?
For example, is the feature adding or removing from a MicroProfile or JavaEE / JakartaEE platform?
Do any existing features need to have new tolerations added for/because of this feature?
Does a new internal versionless feature need to be added for this feature?

Note: This only applies to Jakarta EE and MicroProfile features at this time.

For more information, see https://github.ibm.com/websphere/WS-CD-Open/wiki/Feature-Developers-Guide-for-versionless-features
:::
