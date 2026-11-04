# Evergreen

## about_Evergreen

### SHORT DESCRIPTION

Devuelve la versión más reciente y las URL de descarga de un conjunto de aplicaciones comunes de Windows.

### LONG DESCRIPTION

Evergreen es un módulo de PowerShell que devuelve la versión más reciente y las URL de descarga de un conjunto de aplicaciones comunes de Windows. El módulo consta de funciones sencillas para usar en scripts al realizar varias tareas, entre ellas:

- Recuperar la versión más reciente de una aplicación concreta para compararla con una versión ya instalada o descargada
- Devolver la URL de la versión más reciente de la aplicación para descargarla para su instalación local o implementación en equipos de destino

Evergreen está pensado para usarse en soluciones de automatización de implementaciones de software. Algunas de estas soluciones son:

- Crear imágenes con Hashicorp Packer: se pueden crear imágenes con las versiones más recientes de un conjunto de aplicaciones
- Importar aplicaciones en Microsoft Endpoint Manager: mantener Configuration Manager o Microsoft Intune actualizados con las versiones más recientes de las aplicaciones
- Crear una biblioteca de instaladores de aplicaciones: al ejecutar periódicamente las funciones de Evergreen, se puede recuperar y descargar la versión actual de una aplicación y almacenarla en una estructura de directorios de aplicaciones para usarla más adelante
- Enviar manifiestos a `Winget`, `Chocolatey` o similares: Evergreen puede devolver un objeto con un número de versión y una URL de descarga que se pueden usar para construir manifiestos de las versiones más recientes

Las funciones principales de Evergreen son:

- `Get-EvergreenApp`: devuelve los detalles de la versión más reciente de una aplicación, incluidos el número de versión y la URL de descarga
- `Save-EvergreenApp`: simplifica la descarga de las URL de aplicaciones devueltas por `Get-EvergreenApp`
- `Find-EvergreenApp`: enumera las aplicaciones compatibles con el módulo
