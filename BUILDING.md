##Prerequisites

In order to *build* the tool, you will also need to install the following:
- [AutoIt](https://www.autoitscript.com/site/autoit/downloads/)
- [PDFtk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)

## Building
- Install all the prerequisites listed above.
- Clone the GIT Repository into a local folder
- Copy HANDS_Custom_Generic.au3 to HANDS_Custom.au3
- Customize HANDS_Custom_Generic.au3 to your liking
- Copy "pdftk.exe" and "libiconv2.dll" from
  "C:\Program Files (x86)\PDFtk\bin\" into the local project folder
- Open `HANDS Box.au3`, press F5 to run, or Ctrl-F7 to compile to an EXE.

## Deploying
To deploy, you will need to distribute the following files:
- HANDS Box.exe
- HANDS Box.lnk (Shortcut)
- hands_defaults.ini (Modify for your environment)
- libiconv2.pdf (from PDFtk)
- pdftk.exe
- updateinstall.cmd (or other Update/Install script)
- Sync HANDS Box.ffs_batch (or other sync script, only if needed)
