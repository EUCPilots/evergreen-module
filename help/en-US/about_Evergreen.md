# Evergreen

## about_Evergreen

### SHORT DESCRIPTION

Return the latest version and download URLs for a set of common Windows applications.

### LONG DESCRIPTION

Evergreen is a PowerShell module that returns the latest version and download URLs for a set of common Windows applications. The module consists of simple functions to use in scripts when performing several tasks including:

- Retrieve the latest version of a particular application to comparing against a version already installed or downloaded
- Return the URL for the latest version of the application to download it for local installation or deployment to target machines

Evergreen is intended for use in solutions used to automate software deployments. These solutions could be:

- Image creation with Hashicorp Packer - images can be created with the latest version of a set of applications
- Import applications into Microsoft Endpoint Manager - keep Configuration Manager or Microsoft Intune up to date with the latest versions of applications
- Create a library of application installers - by regularly running Evergreen functions, you can retrieve and download the current version of an application and store it in an application directory structure for later use
- Submitting manifests to `Winget` or `Chocolatey` or similar - Evergreen can return an object with a version number and download URL that can be used to construct manifests for the most recent versions

Primary functions in Evergreen are:

- `Get-EvergreenApp` - returns details of the latest release of an application including the version number and download URL
- `Save-EvergreenApp` - simplifies downloading application URLs returned from `Get-EvergreenApp`
- `Find-EvergreenApp` - lists applications supported by the module
