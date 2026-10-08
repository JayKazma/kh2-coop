#!/bin/sh
# Builds KH2Coop.exe with Mono's compiler against the .NET Framework 4.8 reference assemblies (exact Windows API surface).
cd "$(dirname "$0")/.."
mcs -nologo -sdk:4.8 -target:winexe -platform:x64 -optimize+ -langversion:5 -win32icon:ui/icon.ico -out:KH2Coop.exe \
  -r:System.dll -r:System.Core.dll -r:System.Drawing.dll -r:System.Windows.Forms.dll -r:System.Web.Extensions.dll \
  -r:System.IO.Compression.dll -r:System.IO.Compression.FileSystem.dll \
  -r:lib/Microsoft.Web.WebView2.Core.dll -r:lib/Microsoft.Web.WebView2.WinForms.dll src/Program.cs
