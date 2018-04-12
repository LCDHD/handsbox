rem A simple script to start NextCloud client

echo off
tasklist /fi "IMAGENAME eq nextcloud.exe" | findstr /c:"Image Name">nul && (
echo Nextcloud is Running
) || (
echo Starting Nextcloud
start "" "C:\Program Files (x86)\Nextcloud\nextcloud.exe"
)
