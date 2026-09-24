# Quality Assurance {.unnumbered}

```{=latex}
\sectionslide{Quality Assurance}
```

# Open Source Software

- TODO


::: notes
What Open Source Software will this feature pull in? Include as much information as possible and relevant for the following:
Name of open source project
Location (link)
License
What version (at min) will be used?
If this is not the latest version, why?
Is this a common version used throughout Liberty?
Do any other versions of this OSS already exist in Liberty?
What is the overall health and security posture of the project?  Consider the following to help you answer (Note: these are just guidelines; you are not expected to know or answer all of these; if the info is not readily known/available, just state so):
Does the OSS project accept outside contributions (for example, PRs for fixing issues)
Do we have any committers in the community?
Is there a process to become a committer?
Are reported security vulnerabilities resolved in a timely manner (in-line with timelines practiced in Liberty)?
Are dependencies updated to pull in CVE fixes?
What’s the overall health of the OSS community?  Consider things such as:
How many commits have occurred in last quarter?
How many active contributors?
If known, are all contributions coming from a single company/institution/country or from a diverse pool?
If issues are opened, do they receive appropriate attention?
Anything else that may raise concerns?
:::

# Beta

- TODO


::: notes
All new content needs to be inaccessible in our GA image until the feature is 100% complete and feature focal approvals have been obtained.

How will this content be shielded from our GA image?

The three primary ways of shielding new features from our GA image are:

This is a new Open Liberty feature which will be marked kind=noship or kind=beta.
A new high-level config element is being added to enable this feature and will be marked as “ibm:beta” in the metatype.
A new config attribute in an existing element is being added to enable this feature and will be marked as “ibm:beta” in the metatype.
Mark the function as @deprecated. Then, use the Beta Edition JVM Property to handle the beta fencing. If the property is true, allow the beta method to continue normally and issue a message if its the first time any beta method has been called for that class. If the property is false, throw UnsupportedOperationException. You can access the Beta Edition JVM Property by calling static method getBetaEdition() in com.ibm.ws.kernel.productinfo.ProductInfo in com.ibm.ws.kernel.boot.core. To get tests for beta fenced methods to run, set the beta edition property in jvm.options for the server by adding the following: -Dcom.ibm.ws.beta.edition=true

If you are using one of those 4 options, just say which one.  If you are using a different approach, please describe it.
:::

# Automated Testing

- TODO


::: notes
Describe, in general, expectations around automated testing.  Will a new FAT bucket be added to test this function, or will tests be added to an existing FAT bucket?  If the latter, what bucket will the tests be added to?

If any non-obvious scenarios need to be tested, describe them here.  If there are any other special requirements for automated testing, describe them here.

(This is to assist the developers who will write this function.  We can assume that development teams will add sufficient testing for expected positive and negative code paths, but the UFO should describe any special requirements or unusual testing paths that are needed.)
:::

# System Test Impact

- TODO


::: notes
Describe, in general, expectations around system testing, specifically:

Is System Test required before this feature can GA?  If so, who is the System Test contact for this feature?
Are there scenarios that should be added to the Never Ending System Test (NEST) environment, to help prevent regressions of this feature?
:::

# Performance

- TODO


::: notes
Identify any performance expectations (no affect is ok).

What impact do you expect this to have on the following:

server startup,
memory footprint,
install footprint
throughput.

Identify if you need to work with the performance team for any special performance data. If you expect a throughput impact provide an assessment of what the goal is. If the expected performance impact is high (more than 3% regression) indicate why that should not concern anyone.
:::

# Platform / Cloud Considerations

- TODO


::: notes
Does this feature have any special platform considerations, for example areas where it needs to work differently on z/OS or windows.

If this won’t work on both IBM and Oracle Java state why.

Are there any additional considerations when operating within a cloud environment? For example is there anything special for WASaaS, docker or bluemix instant runtimes.  What about other IaaS or PaaS environments?

List any platform specifics or requirements
Describe any special considerations for running in Clouds environments, like Kubernetes, Cloud Foundry, WASaaS etc
If this UFO is providing a new Liberty feature, the minimum Java version required by that feature should be stated in this slide.  The minimum Java level should be a LTS version of Java.
:::

# Security

- TODO


::: notes
What aspects of this feature could result in an avenue for a potential attacker to exploit. For example if creating a REST API to access files on the file system how do you ensure the API can’t be used to access /etc/passwd or /etc/shadow? Try to think about the following:

Authentication and authorization

Hardening guidelines
Contact the security team for any security hardening guidelines that need to be listed for this feature. For example, if there is an option to use http or https (irrespective of the default) our CIS (Center for Internet Security) hardening benchmark (https://workbench.cisecurity.org/benchmarks/7724) needs to be updated. You can look at the existing recommendations to get more idea or ask the security team. Note that you need to create an account for CIS and become part of the WebSphere community to see the existing benchmarks.

Do you need to identify the client, do you need to apply access control. If so what and how?

Input validation and output encoding

Any input from an untrusted source should be validated to ensure no bad side-effects. Think SQL injection, XSS attack vectors. How can you avoid?

Cryptography and integrity / Data at rest / Data in motion

Are you protecting data in memory and on a network link appropriately. E.g. don’t send a password via http, don’t log/trace passwords.

If you call the Java Crypto API then articulate how you plan to use it, what algorithms etc. This should be sufficient detail to allow someone well versed in crypto to be able to review what you have done and spot holes.

Are there any operating system nuances that affect security? Should any files being delivered be more protected than the default. Most files for Liberty are world readable, should any files be more restricted than that by default? Should it only be visible to a user, or the user and group?

You should create a task to validate that your feature works with Java 2 security.  A personal build should be run with the full feature code enabled, and all relevant FAT and unit tests run in FULL (not just Lite) mode.  The task can be closed when such a build passes with no Java 2 security failures in your new feature code (we understand that there are existing places with Java 2 security failures, which can be ignored for this purpose).

You should create a task to add any audit instrumentation necessary for the feature.  Contact the security team if you are not familiar with the security auditing requirements.  Things that are auditable include, but are not limited to:
Listener ports
REST handlers
Messaging transactions
Authentications outside of core security
Authorizations outside of core security
Accesses to resources (databases, files, etc…)
Sessions
Mbeans
Systems management operations
UI Changes
:::

# Serviceability

- TODO


::: notes
The primary purpose of this slide is to identify the most likely problems users will see and identify how to enable them to diagnose and solve those problems without needing to ask for formal support.

Indicate what team will handle service for downstream products that use this feature.

State the most likely problems a customer will encounter. For each state how the customer can recognize and recover without contacting IBM for support.

What diagnostics will be added to aid in problem determination? Diagnostic frameworks in WAS include trace, logging, ffdc dumpables (tWAS) and introspectors (Liberty). Note that it is not acceptable to expect users to use FFDC or trace to diagnose problems.

Is this feature usable by just enabling the feature in server.xml?  If not, what messages will be presented to the user to guide them to a basic working configuration?  For example, a URL to a guide or Doc page.
:::

# Accessibility Compliance

- TODO


::: notes
Does this feature have any user interfaces (UIs) with which an end user is expected to interact? UI is broadly defined to include Web, Software, Commandline, and Documentation (including Javadocs). If so, then list which UIs are included in this feature. All end user UIs are required to test for accessibility compliance.   If not, then state that the feature has no UI, and does not require accessibility verification testing.

Does this feature generate output that has an end-user user interface?
If so, the output generated by this feature also must be tested for accessibility compliance. It is important to ensure that the end user (the person providing input to the feature for the generated output) has an opportunity to make the output UI accessibility compliant, even if we don't require that they do so. For instance, if the user can include a picture in a generated web page, the picture is required to have alternative text that describes the content of the image. To pass accessibility requirements, the user should have an opportunity to add alternative text. Accessibility testing would fail if the user does not have opportunity to include alternative text for the image. However, accessibility testing would pass if the end user omits the alternative text in their generated output (because they did have the opportunity to do so). And, accessibility would still pass if the user misrepresents the content of the image (e.g., provides alternative text stating the image is an apple, but the image is actually of a banana).
:::

# Migration Impact

- TODO


::: notes
Describe, in general details, known migration concerns for any existing customers and stack products when releasing this feature. Potential impacts could include: programming interfaces, behavior changes, administration scripts, user applications, or default values.

Examples of migration concerns:
Does your feature break Liberty's zero migration policy when no configuration changes are required?
If your feature is implementing a new version of the spec, did the spec deprecate or remove any APIs? Did the spec change behavior for an existing method?
If your feature is an update to an existing feature, determine if there are any behavior changes observed when a customer updates to the new version. Is the new feature switching providers? If so, what are some behavior differences that an application developer may observe when switching between the old and new provider? Is the new feature removing access to any packages previously accessible within the previous version of a feature?
Is your feature dependent on other features? If a customer upgrades to your new feature, do they need to upgrade the dependent features?
The Migration Tools offer a feature list to the customer based on the APIs used in an application. For example, currently, if the tool finds javax.persistence or eclipselink packages, it adds the jpa feature to the feature list. Are there any new packages the migration tools should be associating with your new feature?
:::

# End of UFO {.unnumbered}

```{=latex}
\sectionslide{End of UFO}
```
