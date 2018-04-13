# handsbox
Folder-based Electronic Forms Records for Kentucky HANDS Program.

## In order to *use* the HANDS Box, you will need:
- A file share for storing charts and working files. If you can set up 
  or have access to a secure web server, you might consider:
    - [Nextcloud](https://nextcloud.com/) or [Owncloud](https://owncloud.org/)
    - Otherwise, you will likely need to use a regular Windows file share,
      using a Windows file server connected to your domain, or a
      [Samba](https://www.samba.org/) based file server.
      
- If you choose to store the charts and working files on a Windows file share,
  you will need to install a tool to keep your files in sync, 
  such as one of these:
    - FreeFileSync(https://www.freefilesync.org/download.php)
    - MinFFS(https://github.com/abcdec/MinFFS), an older but completely 
      free version of FreeFileSync, without malware. 
    - SyncToy(https://www.microsoft.com/en-us/download/details.aspx?id=15155)
      (not tested with the HANDS Box)

- You will need a good PDF reader / editor capable of:
    - Filling PDF forms
    - Saving filled forms
    - Digitally signing documents
    - Capturing and affixing signatures from participants (optional)

This has been tested with the following:
- [Foxit Reader](https://www.foxitsoftware.com/pdf-reader/) (Recommended)
- [Nitro Pro](https://www.gonitro.com/)
- [Adobe Acrobat Reader DC](https://get.adobe.com/reader/)
- [Nuance PowerPDF](https://www.nuance.com/print-capture-and-pdf-solutions/pdf-and-document-conversion/power-pdf-converter.html)
- [Master PDF Editor](https://code-industry.net/masterpdfeditor/)

## Quick Start

- The default configuration assumes that all deployment files are copied to
  `Documents\Hands Briefcase\HANDS Documents\Software`
- Run `HANDS Box.exe` and choose the option to 'Install'
- Navigate to the `Setup` tab and choose "Setup Folders"

# Software Overview and Tools

## Folder Structure

On each laptop, there should be a folder structure something like this. The
Working structure will be created automatically by the HANDS Box on first run.

- Documents\HANDS Briefcase
  - Charts.Region1
  - Charts.Region2
  - HANDS Documents *(synced down from server)*
  - Working.MyWindowsUsername *(two-way synced with server)*
    - Labels
    - Needs Correction
    - To Data Processing
    - To Supervisor
    - Tracking Form
    - Work In Progress
  - Working.OtherHomeVisitor
  - Working.MoreStaff
  - Working.Etc.

Synchronize files using a service like Nextcloud or Owncloud. The
GroupFolders app in NextCloud is an excellent option for sharing charts.

Alternatively, set up a file share on a central server and map to each
client laptop, e.g.

    net use H: \\server\HANDS /persistent:yes

Your complete file share will look something like this. You can
  - Charts.Region1
  - Charts.Region2
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
  - Working.Mary.Staff
  - Working.Jane.Staff

Working folder names should exactly match the usernames of the logged in users
on each laptop

Staff should have full read-write permission to their own Working Folders,
and permissions to other working folders and charts as necessary for accessing
data for processing, supervision, etc. Most staff should have read-only access
the HANDS Documents folder to prevent accidental changes to software and
templates. It is suggested that the compiled HANDS Box software be distributed
through the HANDS Documents folder.

## Creating PDF Templates

PDF Templates are regular, fillable PDF documents. Special fields that will
be pre-filled from the "label" should be named EXACTLY as follows:

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

## Building the software

In order to build the software, you will need to download
and install AutoIt, install other prequisites, and compile.

Find details under [BUILDING](BUILDING.md)

## Latest Changes
Find a list of latest changes in [CHANGLOG](CHANGELOG.md)
