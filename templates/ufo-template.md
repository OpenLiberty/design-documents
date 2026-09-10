---
marp: true
theme: default
paginate: true
style: |
  p {
    font-size: 20px;
  }
  li {
    font-size: 16px;
  }

---
<!--
Guidance on using the template
- Use a mix of bullets and full paragraphs as if you were combining a presentation and
  speaker notes in one document.  
- Any referenced images should be checked into source control alongside your markdown.
- Use a markdown editor with a built-in linter such as `vscode` to ensure consistent rendering

CREATING SLIDES/PRESENTATION
- To create slides from this document, you can use Marp (Markdown Presentation Ecosystem):
   - Install Marp VSCode extension or CLI
   - Export to PDF/HTML/PPTX
   - Slide breaks occur at --- Add more slide breaks as needed
   - See https://marp.app/guide/ for more details
--> 

# Title

**Architect:**

**Date:**

**Associated Epic(s):**

---

### Instructions (DELETE ME)

> - The UFO should be high level and focus on user experience
> - Think in terms of the user externals, not implementation.
> - Do not delete any sections. If the section is not applicable, just say "N/A" and add an explanation why it is N/A if it isn't obvious.

---

## Design Thinking
<!-- _class: lead -->

> **NOTE:** This section of the UFO is intended to replicate some of the design thinking goals. It should be high level and user focused.

---

### Technical Background

> **NOTE:** Describe background information that will be useful to help understand how this feature will be used or integrated into the product. Use this section to cover existing concepts and the Key Concepts chart to cover new material that will need documentation.

---

### Problem Statement

> **NOTE:** Describe the problem to be solved. This should not focus on the technical details of the solution, but the technical problem that is being solved from a user perspective.  
> This section is here to help the reviewers and your colleagues understand the problem this feature will solve.

---

### Interested Users

> **NOTE:** Do not list any actual customer names or companies here. Instead generalize what kind of users are interested.  
> For example, instead of "John Doe" or "Company A" write "Users that need to be able to [some task that was not feasible/difficult before that this feature will now address]"

---

### High Level User Stories

> **NOTE:** Identify the user stories this feature is focusing on. More is better, but the follow-on design should identify and focus on the most important ones that feed into the Minimum Viable Product (MVP). The MVP will be defined in a later section.  
> As a (role), I want to (goal) so that (business value).

---

### As-Is

> **NOTE:** For each story in that will be delivered (this may go beyond the MVP, but for initial socialization only the MVP is required. If additional stories are to be delivered the UFO will need to be updated). This should focus on what someone would need to do to get this today. Note that even when adding something net new it is often possible to do it today, but the user experience won't be good. This is to ensure people understand what the user experience would be without this feature.

---

### To-Be

> **NOTE:** For each story that has an As-Is provide the To-Be flow. This will be used to determine if the story is complete, if the to-be isn't achieved the function isn't ready. Note that the UFO should go through each As-Is followed by the equivalent To-Be, not list all As-Is's and then the To-Be's.

---

### Feature Design

> **NOTE:** Include as many charts as needed to depict the key design aspects of the Feature. This should be high level, pictures are more important than words. Do not attempt to go into depth to describe the function of existing components or depth of Feature design. The focus here is to describe key aspects of design usage, additions or changes to existing components and a high level design of new components. The focus is to identify all the major components involved in this Feature and their interactions. Describe the impact or expectations this Feature will have put on those components.  Things to consider:
> - How does this work with all programming models such as OSGi Applications?
> - Are there any multi-version co-existence problems to solve?
> - How is High Availability achieved? How do you avoid single points of failure?
> - Capture any net new open source dependencies. If upgrading make sure we don't ship multiple versions of same open source.

---

### End User Overview

> **NOTE:** Provide an overview (think a single slide) of the function to be provided. The intent of this section is for it to be used in presentations to users. This section should cover the 80% case. Focus on the core intent of the feature. This section should be diagrammatical rather than bullet points. Provide speaker notes to explain the picture rather than bullet points.  
> Advice: This section should be the last section created prior to socialization.

---

## Externals Design
<!-- _class: lead -->

---

### Communication

> **NOTE:** How will the existence of this feature be communicated to users? Every feature will need some form of enablement and this section is where those considerations should be listed.  
> At a minimum the feature should expect to be described in the applicable beta release blog post, and the GA blog post. However depending on the feature one or more of the following should be considered:
>
> - Additional Blog post specific to the feature/functionality (https://openliberty.io/blogs)
> - Sample code demonstrating capability (for example, added to the feature example section on https://openliberty.io/docs Reference/Feature section, like seen in https://openliberty.io/docs/latest/reference/feature/appSecurity.html#_examples)
> - YouTube video demonstrating capability
> - Sample scripts to drive capability
> - Getting started guide to use feature (doc and/or video)
> - Communication on social media
> - Open Liberty guides (https://openliberty.io/guides). Engaging developers and the community is important and key to our Open Liberty's strategy. Open Liberty guides are designed to take developers through a particular topic or technology in 15 or 20 mins providing meaningful learning experience to engage them. If the feature applies to Open Liberty and is relevant to developers, consider if guides should be created to engage developers and the community. Contact YK Chang if you need help determining if a guide is appropriate.
>
> These might be delivered via WASdev.net, the middleware blog, the WASdev github org, openliberty.io, the OpenLiberty github org or elsewhere.  
> When looking at this section you MUST identify the target audience for what is being provided and should be related into the dev/ops lifecycle.  
> Make sure you contact the publication venue early to ensure that it is an appropriate place to put the content; you don't want to ask someone to publish something that is done only to discover they say no.

---

### Java APIs/SPIs

> **NOTE:** Provide an initial Java API proposal for any product API or SPIs. When going through the implementation it may be discovered that the API needs to evolve, however the Java API/SPI needs to be designed with the developer who calls it in mind, rather than what is easiest for the implementation.  
> Include and mark any third-party APIs/SPIs that this feature provides.  
> New features should only expose the public APIs and functions that they actually require. They should not expose any additional public APIs and functions that happen to be used by the internal implementation.  
> Show how the API/SPI will be used, rather than every detail of the API. Focus on the 80% path.  
> For OL features, follow this naming convention for packages:
>
> - API - `io.openliberty.xxx`
> - SPI - `io.openliberty.xxx.spi`
> - Internal - `io.openliberty.xxx.internal`

---

### RESTful API Design

> **NOTE:** If REST endpoints are being exposed by this feature you must document:  
> (1) What they are (URL, HTTP verbs, HTTP headers, query / form parameters, payload formats, security domain, versioning model, resource design)  
> (2) How they will be exposed (REST Handler, z/OS Connect, WAB, J2EE App, Http Whiteboard, etc)  
> The goal is to have a discussion about the types of resources being exposed and how they are being exposed. The focus is on RESTful best practices. It is more important to focus on how the RESTful API is to be used, rather than every detail of the API. Focus on the 80% path.

---

### Admin / Config / Command Line

> **NOTE:** Describe how to configure and administer this feature. Follow the Open Liberty config design practices, less configuration is better. Show examples of the configuration, relate back to the user stories earlier in this section. Focus on the 80% path and minimal configuration. If the config is only required by 10% of users, do we really need it?  
> If the feature needs new command line utilities or script, this is where to include it.  
> Should any component of this feature be "Pauseable", i.e. support being stopped and started when an administrator issues the "server pause" and "server resume" command? The pause command is intended to allow an administrator to pause and resume portions of the application server that handle external requests; for example, all of our HTTP listeners are pauseable. Also note that all "Pauseable" components are paused during the quiesce phase of server shutdown.  
> If you're doing server.bat/server(.sh) changes, be aware the z/OS started task bypasses the script and uses other C code instead, so you should make sure you don't also need to make changes over there.  
> For SSO features, make sure that any new attributes are consistent across the SSO features (SPNEGO, LTPA, OIDC, SAML, OAUTH, etc.).

---

### Developer Experience

> **NOTE:** Describe the experience of a developer using this feature. What changes are required in the developer tools for Liberty and/or tWAS? What about moving from development to deployment? How does this fit into a build/automated deploy pipeline? Are there any open source/third party packages that should integrate with this capability? Some things to consider:
>
> 1. Liberty Starter
> 2. Liberty's dev mode
> 3. IDEs
>    - Eclipse
>    - IntelliJ
>    - VS Code
>    - Others
> 4. Language servers
>    - Jakarta EE
>    - MicroProfile
>    - Liberty configuration
> 5. Build tools
>    - Maven (and Liberty Maven plugin)
>    - Gradle (and Liberty Gradle plugin)
>    - Ant
> 6. Command line
> 7. Deployment
>    - OpenShift Pipelines
>    - Ansible
>    - Podman or Docker
>    - Popular CI/CD/DevOps tools
>
> Note to System Testers: Since you are the first consumers of the feature, if you feel the Developer Experience is lacking, that is valuable input!

---

### Deprecation & Stabilization

> **NOTE:** Describe, in general details, any capabilities that will be stabilized by this feature.  
> Open Liberty Features cannot be deprecated (only stabilized).  
> What is the impact to existing test applications?

---

### Monitoring

> **NOTE:** How does a user monitor this feature to detect and diagnose problems.  
> What new PMI metrics are needed (for new pools, queues, etc. that need visibility)?  
> What new events does your design introduce that should be timed at runtime (Liberty request probes)?

---

### InstantOn

> **NOTE:** All new, public Liberty features that can be enabled by the feature manager are expected to support InstantOn. New functionality must support InstantOn that is added to existing features that already support InstantOn. For InstantOn support the largest concern is how the feature reacts to Liberty configuration updates when restoring a running application instant. Be sure to answer the following questions with regard to InstantOn support. If the new functionality is not part of the Liberty runtime itself then mark this section as N/A, for example, new command line utilities.
>
> - Does the functionality provided by this UFO support InstantOn? If not, justify why not.
> - Can the feature respond to dynamic updates to Liberty configuration associated with the feature? If not, identify the configuration.
> - Do dynamic updates to Liberty configuration associated with the feature require applications to restart? If so, identify the configuration.
> - Is there Liberty configuration associated with the feature that is typically only known at the time the application is deployed? If so, identify the configuration. For example, hostname, port or credentials to connect to a remote resource.
> - For Liberty configuration that is typically only known at the time the application is deployed, can the server tolerate being started without the configuration present? How would the configuration be parameterized such that it can be set at deployment time?
> - Does the feature establish state while the server is starting or an application is starting which needs special consideration when restoring an application process into multiple running instances? For example, a unique ID (e.g. UUID) that must be unique for each running instance of the application.

---

### Versionless Features

> **NOTE:** All new Liberty features that belong to the MicroProfile or JavaEE / JakartaEE platforms are expected to support versionless features. Answer the following questions to determine if your changes involve versionless features:
>
> - Does this feature have any effect on versionless features, or introduce a new versionless feature? For example, is the feature adding or removing from a MicroProfile or JavaEE / JakartaEE platform?
> - Do any existing features need to have new tolerations added for/because of this feature?
> - Does a new internal versionless feature need to be added for this feature?
>
> Note: This only applies to Jakarta EE and MicroProfile features at this time.  
> For more information, see https://github.ibm.com/websphere/WS-CD-Open/wiki/Feature-Developers-Guide-for-versionless-features.

---

## Quality Assurance
<!-- _class: lead -->

---

### Open Source Software

> **NOTE:** What Open Source Software will this feature pull in? 
>Include as much information as possible and relevant for the following:
>
> - Name of open source project
> - Location (link)
> - License
> - What version (at min) will be used? If this is not the latest version, why? Is this a common version used throughout Liberty? Do any other versions of this OSS already exist in Liberty?
> - What is the overall health and security posture of the project? Consider the following to help you answer (Note: these are just guidelines; you are not expected to know or answer all of these; if the info is not readily known/available, just state so):
>   - Does the OSS project accept outside contributions (for example, PRs for fixing issues)
>   - Do we have any committers in the community?
>   - Is there a process to become a committer?
>   - Are reported security vulnerabilities resolved in a timely manner (in-line with timelines practiced in Liberty)?
>   - Are dependencies updated to pull in CVE fixes?
>   - What's the overall health of the OSS community? Consider things such as: How many commits have occurred in last quarter? How many active contributors? If known, are all contributions coming from a single company/institution/country or from a diverse pool? If issues are opened, do they receive appropriate attention?
>   - Anything else that may raise concerns?

---

### Beta

> **NOTE:** All new content needs to be inaccessible in our GA image until the feature is 100% complete and feature focal approvals have been obtained.  
> How will this content be shielded from our GA image?  

> The three primary ways of shielding new features from our GA image are:
>
> 1. This is a new Open Liberty feature which will be marked `kind=noship` or `kind=beta`.
> 2. A new high-level config element is being added to enable this feature and will be marked as `"ibm:beta"` in the metatype.
>(See numbers 3 + 4 on the next slide)
> 3. A new config attribute in an existing element is being added to enable this feature and will be marked as `"ibm:beta"` in the metatype.
> 4. Mark the function as `@deprecated`. Then, use the Beta Edition JVM Property to handle the beta fencing. If the property is true, allow the beta method to continue normally and issue a message if its the first time any beta method has been called for that class. If the property is false, throw `UnsupportedOperationException`. You can access the Beta Edition JVM Property by calling static method `getBetaEdition()` in `com.ibm.ws.kernel.productinfo.ProductInfo` in `com.ibm.ws.kernel.boot.core`. To get tests for beta fenced methods to run, set the beta edition property in jvm.options for the server by adding the following: `-Dcom.ibm.ws.beta.edition=true`
>
> If you are using one of those 4 options, just say which one. If you are using a different approach, please describe it.

---

### Automated Testing

> **NOTE:** Describe, in general, expectations around automated testing. Will a new FAT bucket be added to test this function, or will tests be added to an existing FAT bucket? If the latter, what bucket will the tests be added to?  
> If any non-obvious scenarios need to be tested, describe them here. If there are any other special requirements for automated testing, describe them here.  
> (This is to assist the developers who will write this function. We can assume that development teams will add sufficient testing for expected positive and negative code paths, but the UFO should describe any special requirements or unusual testing paths that are needed.)

---

### System Test Impact

> **NOTE:** Describe, in general, expectations around system testing, specifically:
>
> - Is System Test required before this feature can GA? If so, who is the System Test contact for this feature?
> - Are there scenarios that should be added to the Never Ending System Test (NEST) environment, to help prevent regressions of this feature?

---

### Performance

> **NOTE:** Identify any performance expectations (no affect is ok).  
> What impact do you expect this to have on the following:
>
> - server startup
> - memory footprint
> - install footprint
> - throughput
>
> Identify if you need to work with the performance team for any special performance data. If you expect a throughput impact provide an assessment of what the goal is. If the expected performance impact is high (more than 3% regression) indicate why that should not concern anyone.

---

### Platform / Cloud Considerations

> **NOTE:** Does this feature have any special platform considerations, for example areas where it needs to work differently on z/OS or windows.  
> If this won't work on both IBM and Oracle Java state why.  
> Are there any additional considerations when operating within a cloud environment? For example is there anything special for WASaaS, docker or bluemix instant runtimes. What about other IaaS or PaaS environments?  
> List any platform specifics or requirements  
> Describe any special considerations for running in Clouds environments, like Kubernetes, Cloud Foundry, WASaaS etc  
> If this UFO is providing a new Liberty feature, the minimum Java version required by that feature should be stated in this section. The minimum Java level should be a LTS version of Java.

---

### Security

> **NOTE:** What aspects of this feature could result in an avenue for a potential attacker to exploit. For example if creating a REST API to access files on the file system how do you ensure the API can't be used to access /etc/passwd or /etc/shadow? Try to think about the following:  
> Authentication and authorization  
> Hardening guidelines  
> Contact the security team for any security hardening guidelines that need to be listed for this feature. For example, if there is an option to use http or https (irrespective of the default) our CIS (Center for Internet Security) hardening benchmark (https://workbench.cisecurity.org/benchmarks/7724) needs to be updated. You can look at the existing recommendations to get more idea or ask the security team. Note that you need to create an account for CIS and become part of the WebSphere community to see the existing benchmarks.  
> Do you need to identify the client, do you need to apply access control. If so what and how?  
> Input validation and output encoding  
> Any input from an untrusted source should be validated to ensure no bad side-effects. Think SQL injection, XSS attack vectors. How can you avoid?  
> Cryptography and integrity / Data at rest / Data in motion  
> Are you protecting data in memory and on a network link appropriately. E.g. don't send a password via http, don't log/trace passwords.  
> If you call the Java Crypto API then articulate how you plan to use it, what algorithms etc. This should be sufficient detail to allow someone well versed in crypto to be able to review what you have done and spot holes.  
> Are there any operating system nuances that affect security? Should any files being delivered be more protected than the default. Most files for Liberty are world readable, should any files be more restricted than that by default? Should it only be visible to a user, or the user and group? 
> You should create a task to validate that your feature works with Java 2 security. A personal build should be run with the full feature code enabled, and all relevant FAT and unit tests run in FULL (not just Lite) mode. The task can be closed when such a build passes with no Java 2 security failures in your new feature code (we understand that there are existing places with Java 2 security failures, which can be ignored for this purpose).  
> You should create a task to add any audit instrumentation necessary for the feature. Contact the security team if you are not familiar with the security auditing requirements. Things that are auditable include, but are not limited to:
>
> - Listener ports
> - REST handlers
> - Messaging transactions
> - Authentications outside of core security
> - Authorizations outside of core security
> - Accesses to resources (databases, files, etc…)
> - Sessions
> - Mbeans
> - Systems management operations
> - UI Changes

---

### Serviceability

> **NOTE:** The primary purpose of this section is to identify the most likely problems users will see and identify how to enable them to diagnose and solve those problems without needing to ask for formal support.  
> Indicate what team will handle service for downstream products that use this feature.  
> State the most likely problems a customer will encounter. For each state how the customer can recognize and recover without contacting IBM for support.  
> What diagnostics will be added to aid in problem determination? Diagnostic frameworks in WAS include trace, logging, ffdc dumpables (tWAS) and introspectors (Liberty). Note that it is not acceptable to expect users to use FFDC or trace to diagnose problems.  
> Is this feature usable by just enabling the feature in server.xml? If not, what messages will be presented to the user to guide them to a basic working configuration? For example, a URL to a guide or Doc page.

---

### Accessibility Compliance

> **NOTE:** Does this feature have any user interfaces (UIs) with which an end user is expected to interact? UI is broadly defined to include Web, Software, Commandline, and Documentation (including Javadocs). If so, then list which UIs are included in this feature. All end user UIs are required to test for accessibility compliance. If not, then state that the feature has no UI, and does not require accessibility verification testing.  
> Does this feature generate output that has an end-user user interface?  
> If so, the output generated by this feature also must be tested for accessibility compliance. It is important to ensure that the end user (the person providing input to the feature for the generated output) has an opportunity to make the output UI accessibility compliant, even if we don't require that they do so. For instance, if the user can include a picture in a generated web page, the picture is required to have alternative text that describes the content of the image. To pass accessibility requirements, the user should have an opportunity to add alternative text. Accessibility testing would fail if the user does not have opportunity to include alternative text for the image. However, accessibility testing would pass if the end user omits the alternative text in their generated output (because they did have the opportunity to do so). And, accessibility would still pass if the user misrepresents the content of the image (e.g., provides alternative text stating the image is an apple, but the image is actually of a banana).

---

### Migration Impact

> **NOTE:** Describe, in general details, known migration concerns for any existing customers and stack products when releasing this feature. Potential impacts could include: programming interfaces, behavior changes, administration scripts, user applications, or default values.  
> Examples of migration concerns:
>
> - Does your feature break Liberty's zero migration policy when no configuration changes are required?
> - If your feature is implementing a new version of the spec, did the spec deprecate or remove any APIs? Did the spec change behavior for an existing method?
> - If your feature is an update to an existing feature, determine if there are any behavior changes observed when a customer updates to the new version. Is the new feature switching providers? If so, what are some behavior differences that an application developer may observe when switching between the old and new provider? Is the new feature removing access to any packages previously accessible within the previous version of a feature?
> - Is your feature dependent on other features? If a customer upgrades to your new feature, do they need to upgrade the dependent features?
>
> The Migration Tools offer a feature list to the customer based on the APIs used in an application. For example, currently, if the tool finds `javax.persistence` or eclipselink packages, it adds the jpa feature to the feature list. Are there any new packages the migration tools should be associating with your new feature?

---

## End of UFO