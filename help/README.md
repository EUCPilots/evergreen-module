# Evergreen Help

The platyPS Markdown help sources are organized by locale under `help/`. The
module's generated external help files are stored in the matching locale
directory under `Evergreen/`.

| Locale | Language |
| --- | --- |
| `en-US` | English |
| `es-ES` | Spanish |
| `fr-FR` | French |
| `de-DE` | German |
| `ja-JP` | Japanese |

After editing the help sources, generate external help for every locale:

```powershell
$Locales = @('en-US', 'es-ES', 'fr-FR', 'de-DE', 'ja-JP')
foreach ($Locale in $Locales) {
    New-ExternalHelp -Path "help/$Locale" -OutputPath "Evergreen/$Locale" `
        -Encoding ([System.Text.Encoding]::UTF8) -Force
}
```

To update English Markdown help from the module's command metadata, use
`Update-MarkdownHelpModule -Path "help/en-US"`. Review and translate any
resulting changes in the other locale directories before regenerating external
help.
