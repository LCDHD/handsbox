# handsbox
Folder-based Electronic Forms Records for Kentucky HANDS Program

# Prerequisites


In order to use the tool, you will also need to install the following:
- [AutoIt](https://www.autoitscript.com/site/autoit/downloads/)
- [FreeFileSync](https://www.freefilesync.org/download.php) 
- [PDFtk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)

Last, but not least, you will need some type of PDF software installed. This has been tested with:

- Adobe Acrobat / Adobe Acrobat Reader / Adobe Acrobat Reader DC
- Nitro Pro
- Nuance PDF Converter

# Quick Start

- Install all the prerequisites listed above.
- Clone the GIT Repository into a local folder
- Copy HANDS_Custom_Generic.au3 to HANDS_Custom.au3
- Open `HANDS Box.au3`, press F5 to run, or Ctrl-F7 to compile to an EXE.
- Run the `HANDS Box`, click the "Setup" tab and then click the "Setup..." button.
- Open `Documents\Hands Briefcase\HANDS Documents\Forms,` create folders named `English` and `Spanish` and copy PDF template forms here.

# Software Overview and Tools

## Creating PDF Templates

PDF Templates are regular, fillable PDF documents. Special fields that will be pre-filled from the "label" should be named EXACTLY as follows:

- _LCDHD_FSW (Home Visitor's Full Name)
- _LCDHD_SSN (Patient ID or SSN)
- _LCDHD_CLID (Clinic ID)
- _LCDHD_DOB (Patient Date of Birth)
- _LCDHD_LNAME (Patient's Last Name)
- _LCDHD_FNAME (Patient's First Name)
- _LCDHD_MI (Patient's Middle Initial)
- _LCDHD_BILLING (Billing Code)
- _LCDHD_NAME (Patient's Full Name)
- _LCDHD_FORMDATE (Date of Form)

PDF Templates should be named with the following convention:
```
FORM NUMBER - Form Title (Form Date) [CODE].pdf
```
