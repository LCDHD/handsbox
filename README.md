# handsbox
Folder-based Electronic Forms Records for Kentucky HANDS Program

# Prerequisites

In order to *build* the tool, you will also need to install the following:
- [AutoIt](https://www.autoitscript.com/site/autoit/downloads/)
- [PDFtk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)

In order to *use* the tool, you will need
- A file share for storing charts and working files
- [FreeFileSync](https://www.freefilesync.org/download.php)
- PDF software (see below)

A PDF reader / editor capable of:
- Filling PDF forms
- Saving filled forms
- Digitally signing documents
- Capturing and affixing signatures from participants (optional)

This has been tested with the following:
- [Foxit Reader](https://www.foxitsoftware.com/pdf-reader/) (Recommended)
- [Nitro Pro](https://www.gonitro.com/) (Recommended)
- [Nitro PDF Reader](https://www.gonitro.com/pdf-reader)
- [Adobe Acrobat Reader DC](https://get.adobe.com/reader/)
- [Nuance PowerPDF](https://www.nuance.com/print-capture-and-pdf-solutions/pdf-and-document-conversion/power-pdf-converter.html)
- [Master PDF Editor](https://code-industry.net/masterpdfeditor/)

# Quick Start

- Install all the prerequisites listed above.
- Clone the GIT Repository into a local folder
- Copy HANDS_Custom_Generic.au3 to HANDS_Custom.au3
- Copy "pdftk.exe" and "libiconv2.dll" from "C:\Program Files (x86)\PDFtk\bin\" into the local project folder
- Open `HANDS Box.au3`, press F5 to run, or Ctrl-F7 to compile to an EXE.
- Run the `HANDS Box`, click the "Setup" tab and then click the "Setup..." button.
- Open `Documents\Hands Briefcase\HANDS Documents\Forms,` create folders named `English` and `Spanish` and copy PDF template forms here.

# Software Overview and Tools

## Folder Structure

On each laptop, there should be a folder structure something like this. The Working structure will be created automatically by the HANDS Box on first run.

- Documents\HANDS Briefcase
  - HANDS Documents *(synced down from server)*
  - Working *(two-way synced with server)*
    - Labels
    - Needs Correction
    - To Data Processing
    - To Supervisor
    - Tracking Form
    - Work In Progress

Set up a file share on a central server and map to each client laptop, e.g.

    net use H: \\server\HANDS /persistent:yes

- H:\
  - Charts
  - HANDS Documents
    - Forms
      - English
        - ABC 101 - Parent Entry Form [A].pdf
        - ABC 102 - Parent Exit Form [A].pdf
        - ADM 100 - Entry Packet [A].txt
      - Spanish
      - billingcodes.txt
    - Software
    - Supervision Forms
  - Working Folders
    - Mary.Staff
    - Jane.Staff

Working folder names should exactly match the usernames of the logged in users on each laptop
Staff should have full read-write permission to their own Working Folders, and permissions to other working folders and charts as necessary for accessing data for processing, supervision, etc. Most staff should have read-only access the HANDS Documents folder to prevent accidental changes to software and templates. It is suggested that the compiled HANDS Box software be distributed through the HANDS Documents folder.

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
