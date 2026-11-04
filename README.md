# About

This is the repository the the Evergreen PowerShell module. For the Evergreen application functions see [eucpilots/evergreen-apps](https://github.com/EUCPilots/evergreen-apps).

[![License][license-badge]][license]
[![PowerShell Gallery Version][psgallery-version-badge]][psgallery]
[![PowerShell Gallery][psgallery-badge]][psgallery]

![Evergreen icon](/img/evergreenbulb.png)

Evergreen is a simple PowerShell module to return the latest version and download URLs for a set of common enterprise Windows applications. The module consists of a number of simple functions to use in scripts when performing several tasks including:

* [Image creation with Hashicorp Packer](https://github.com/aaronparker/packer) - images can be created with the latest version of a set of applications
* Import applications into Configuration Manager or [Microsoft Intune](https://github.com/aaronparker/packagefactory) and keep applications up to date with the latest versions
* Validating or auditing a desktop image to ensure the current version of an application is installed
* Create a [library of application installers](https://eucpilots.com/evergreen/newlibrary/) - by regularly running Evergreen functions, you can retrieve and download the current version of an application and store it in an application directory structure for later use
* [Track application updates](https://stealthpuppy.com/apptracker) to stay on top of new releases
* Submitting manifests to `Winget` or `Chocolatey` or similar - Evergreen can return an object with a version number and download URL that can be used to construct manifests for the most recent versions

Via `Get-EvergreenApp` each Evergreen application returns at least two properties in the object sent to the pipeline:

* `Version` - a string property that is the version number of the application. If you need these in a version format, cast them with `[System.Version]`
* `URI` - a string property that is the download location for the latest version of the application. These will be publicly available locations that provide installers in typically Windows installer formats, e.g., `exe`, `msi`. Some downloads may be in other formats, such as `zip` that will need to be extracted before install

## How Evergreen Works

**Application version and download links are only pulled from official sources (vendor's web site, vendor's application update API, GitHub, SourceForge etc.) and never a third party**.

Evergreen uses an approach that returns at least the version number and download URI for applications programmatically - thus for each run an Evergreen function it should return the latest version and download link.

Evergreen uses several strategies to return the latest version of software:

1. Application update APIs - by using the same approach as the application itself, Evergreen can consistently return the latest version number and download URI - e.g., [Microsoft Edge](/Evergreen/Public/Get-MicrosoftEdge.ps1), [Mozilla Firefox](/Evergreen/Apps/Get-MozillaFirefox.ps1) or [Microsoft OneDrive](/Evergreen/Apps/Get-MicrosoftOneDrive.ps1). [Fiddler](https://www.telerik.com/fiddler) can often be used to find where an application queries for updates
2. Repository APIs - repo hosts including GitHub and SourceForge have APIs that can be queried to return application version and download links - e.g., [Audacity](/Evergreen/Apps/Get-Audacity.ps1), [Notepad++](/Evergreen/Apps/Get-NotepadPlusPlus.ps1) or [WinMerge](/Evergreen/Apps/Get-WinMerge.ps1)
3. Web page queries - often a vendor download pages will include a query that returns JSON when listing versions and download links - this avoids page scraping. Evergreen can mimic this approach to return application download URLs; however, this approach is likely to fail if the vendor changes how their pages work - e.g., [Adobe Acrobat Reader DC](/Evergreen/Apps/Get-AdobeAcrobatReaderDC.ps1)
4. Static URLs - some vendors provide static or evergreen URLs to their application installers. These URLs often provide additional information in the URL that can be used to determine the application version and can be resolved to the actual target URL - e.g., [Microsoft FSLogix Apps](/Evergreen/Apps/Get-MicrosoftFSLogixApps.ps1) or [Zoom](/Evergreen/Apps/Get-Zoom.ps1)

## What Evergreen Doesn't Do

Evergreen does not scrape HTML - scraping web pages to parse text and determine version strings and download URLs can be problematic when text in the page changes or the page is out of date. Pull requests that use web page scraping will be closed.

While the use of RegEx to determine application properties (particularly version numbers) is used for some applications, this approach is not preferred, if possible.

For additional applications where the only recourse it to use web page scraping, see the [Nevergreen](https://github.com/DanGough/Nevergreen) project.

## Why

There are several community and commercial products that manage application deployment and updates already. This module isn't intended to compete against those. In fact, they can be complementary - for example, Evergreen can be used with the [Chocolatey Automatic Package Updater Module](https://www.powershellgallery.com/packages/AU/) to find the latest version of an application and then creating and submitting a Chocolatey package, or it can be used to create a [Windows Package Manager](https://github.com/microsoft/winget-create) manifest.

Evergreen's focus is on integration for PowerShell scripts to provide product version numbers and download URLs. Ideal for use with the Microsoft Deployment Toolkit or Microsoft Configuration Manager for operating system deployment, creating applications packages in Microsoft Intune, or with [Packer](https://www.packer.io/) to create evergreen machine images in Azure, AWS, GCP etc.

## Documentation

Documentation for Evergreen, including usage examples, is located here: [https://eucpilots.com/evergreen/](https://eucpilots.com/evergreen/).

## Testing

The [Validate module workflow](.github/workflows/validate-module.yml) runs deterministic Pester tests on Windows PowerShell 5.1, PowerShell 7.4.0 (the minimum supported 7.4 line) on Windows, and the runner-provided PowerShell 7 on Windows, Linux, and macOS. Each runtime uploads a separate test report. Failed tests, discovery/setup failures, an empty run, an unexpected skip, inconclusive tests, or a required suite with no passing tests fail validation. Code coverage remains in the live Windows PowerShell job, avoiding debugger instrumentation in the compatibility matrix.

The [release workflow](.github/workflows/update-module.yml) calls the same [runtime matrix](.github/workflows/test-runtimes.yml) against the release commit before publishing to the PowerShell Gallery. Every runtime must pass; a compatibility failure or the 20-minute job timeout blocks publication.

The deterministic matrix uses an isolated apps-cache path and does not run `Update-Evergreen`. Tests tagged `Integration` and the companion-cache suites for `Find-EvergreenApp`, `Export-EvergreenManifest`, `Get-EvergreenApp`, `Test-EvergreenLibrary`, and `Update-Evergreen` remain in the separate live Windows PowerShell job. The separate [Get-EvergreenApp unit suite](tests/Public/Get-EvergreenApp.Unit.Tests.ps1) runs offline with local application and filter fixtures, covering execution, parameter validation, error reporting, and proxy/certificate cleanup without downloading the companion cache. Library and URI-check tests also use local fixtures or mocked requests. Platform-specific tests and repository-helper cases that do not apply to a particular helper can be skipped. Existing disabled library integration scenarios are not part of the deterministic matrix.

To run the same deterministic checks locally:

```powershell
.\tests\Invoke-Tests.ps1
```

The runner installs Pester 5.7.1 if needed and writes reports to `tests/Results`. Use `-OutputPath` to choose another report directory. Add `-IncludeIntegration` to download the apps cache and run the full suite, including live-service tests and code coverage.

### Analysis and coverage gates

The [analyzer workflow](.github/workflows/psscriptanalyzer.yml) runs default rules, the custom lowercase-keyword rule, explicit PowerShell 5.1/7.4 syntax checks, and command-compatibility checks against the bundled profiles for Windows PowerShell 5.1 and Windows/Linux PowerShell 7.0. Errors and Warnings fail validation; `PSAvoidUsingWriteHost` remains excluded. SARIF is uploaded even when findings fail the job. The runtime matrix separately tests the PowerShell 7.4 minimum on Windows and runner-provided PowerShell 7 on Windows, Linux, and macOS. Existing findings are blockers, not grandfathered exceptions.

The runtime matrix parses module and CI `.ps1`, `.psm1`, and `.psd1` files under each engine. The [release-gates workflow](.github/workflows/validate-release.yml) also validates workflow YAML with actionlint and parses embedded PowerShell.

Deterministic coverage runs separately on Windows PowerShell 5.1 with `-CollectCoverage`. The [coverage baseline](.rules/CoverageBaseline.json) records 3,103 covered commands out of 3,847 (80.66%), measured with Pester 5.7.1. Overall coverage must not fall below that exact ratio. Changed critical files listed in the policy require at least 90% command coverage, including files with no reported coverage (which fail). Comparisons use the PR base commit, the previous push commit, or the previous release tag for releases.

```powershell
.\tests\Invoke-Tests.ps1 -CollectCoverage
. .\ci\Test-Coverage.ps1
Test-Coverage -ReportPath .\tests\Results\CodeCoverage.xml -BaseRef HEAD^
.\ci\Test-Analysis.ps1
.\ci\Test-Workflows.ps1
```

Baseline and critical-file-list changes require deliberate review. Remeasure with the same runtime and pinned Pester version; do not lower the baseline to make a failing run pass. Raise the baseline when adopting improved coverage. Test and release-tool versions are centralized in [ValidationTools.psd1](ci/ValidationTools.psd1).

### Publication gates

Release runs are serialized without cancelling an active release. Publication depends on runtime tests, static analysis, deterministic coverage, and workflow validation for the exact release commit.

Before staging and again immediately before publishing, [release validation](ci/Test-Release.ps1) checks:

- The candidate version is greater than the stable version returned by the PowerShell Gallery; Gallery lookup failures block release.
- The tag name, tag commit, tested commit, checkout, and module manifest version agree.
- The changelog has nonempty notes for the candidate version, with no `## VERSION` heading or unresolved release placeholders; manifest release notes also identify the candidate.
- Source and staged files exactly match the reviewed [package inventory](.rules/PackageInventory.json), contain no links, and have identical SHA-256 hashes.

The validated module directory is uploaded as a release artifact and downloaded by the publishing job. Only this revalidated directory is passed to `Publish-Module`. Additions or removals of module files require an explicit inventory update. Version commits and tags are created before validation; a blocked release can therefore leave a tag without a Gallery publication.

Starting a new **Update and publish module** run after a blocked release does not require restoring `## VERSION`. If the first changelog section and an existing tag match the manifest version, the workflow increments the third version component (for example, `2611.2865.0` to `2611.2865.1`), reuses the notes, and updates that section and the manifest to the new version. Existing tags are preserved, and occupied candidate tags are skipped by incrementing the third component again. A new `## VERSION` section retains the normal date-based version and second-component increment of three. Missing or mismatched release notes still block the run.

The tag step fetches existing tags before creating one. An existing tag is reused only when it points to the release commit; a tag pointing elsewhere blocks the run and is never overwritten.

The live job tests a random sample of 30 applications with `Get-EvergreenApp` by default. To test all applications except the explicit exclusion list, run the workflow manually from GitHub Actions and enable **Test all applications**. Push and pull request runs continue to use the random sample.

For local live Pester runs, set `$env:EVERGREEN_TEST_ALL_APPLICATIONS = "true"` before running the tests to use the expanded application set (excluding the explicit exclusion list). Remove the variable with `Remove-Item Env:\EVERGREEN_TEST_ALL_APPLICATIONS` to restore the default random sample.

## Versioning

The module uses a version notation that follows: YearMonth.Build. It is expected that the module will have changes on a regular basis, so the version numbering is intended to make it as simple as possible to understand when the last update was made. See the [CHANGELOG](https://eucpilots.com/evergreen/changelog/) for details on changes introduced in each version.

## Installing the Module

### PowerShell Support

Evergreen supports Windows PowerShell 5.1 and PowerShell 7.4+. Evergreen should work on PowerShell Core 6.x and PowerShell 7.0 to 7.3; however, we are not actively testing on those versions of PowerShell, so support cannot be guaranteed.

### Install from the PowerShell Gallery

The Evergreen module is published to the PowerShell Gallery and can be found here: [Evergreen](https://www.powershellgallery.com/packages/Evergreen/). This is the best and recommend method to install Evergreen.

The module can be installed from the gallery with:

```powershell
Install-Module -Name Evergreen
Import-Module -Name Evergreen
Update-Evergreen
```

#### Updating the Module

If you have installed a previous version of the module from the gallery, you can install the latest update with `Update-Module` and the `-Force` parameter:

```powershell
Update-Module -Name Evergreen -Force
Update-Evergreen
```

### Manual Installation from the Repository

The module can be downloaded from the [GitHub source repository](https://github.com/aaronparker/evergreen) and includes the module in the `Evergreen` folder. The folder needs to be installed into one of your PowerShell Module Paths. To see the full list of available PowerShell Module paths, use `$env:PSModulePath.split(';')` in a PowerShell console.

Common PowerShell module paths include:

* Current User: `%USERPROFILE%\Documents\WindowsPowerShell\Modules\`
* All Users: `%ProgramFiles%\WindowsPowerShell\Modules\`
* OneDrive: `$env:OneDrive\Documents\WindowsPowerShell\Modules\`

To install from the repository

1. Download the `main branch` to your workstation
2. Copy the contents of the Evergreen folder onto your workstation into the desired PowerShell Module path
3. Open a Powershell console with the Run as Administrator option
4. Run `Set-ExecutionPolicy` using the parameter `RemoteSigned` or `Bypass`
5. Unblock the files with `Get-ChildItem -Path <path to module> -Recurse | Unblock-File`

Once installation is complete, you can validate that the module exists by running `Get-Module -ListAvailable Evergreen`. To use the module, load it with:

```powershell
Import-Module -Name Evergreen
Update-Evergreen
```

[psgallery-badge]: https://img.shields.io/powershellgallery/dt/Evergreen.svg?style=flat-square
[psgallery]: https://www.powershellgallery.com/packages/Evergreen
[psgallery-version-badge]: https://img.shields.io/powershellgallery/v/Evergreen.svg?style=flat-square
[license-badge]: https://img.shields.io/github/license/aaronparker/Evergreen.svg?style=flat-square
[license]: /LICENSE

---
[Greentech icon by Icons8](https://icons8.com/icon/set/bulb/3d-fluency)
