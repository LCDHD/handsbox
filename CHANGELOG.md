# Changelog for HANDS box
Notable changes to HANDS Box at each version

## [1.3.4] - 2018-01-25
### Changed
- Added user's own name to the listing of home visitors in the Supervisor /
  Data Entry staff tab. (Feature Request)

## [1.3.3] - 2018-01-25
### Added
- Add a rudimentary check for PDF signatures to display the name(s)
  of the signers when queuing forms
- Add feature to prompt before deleting blank forms in the working folder

### Changed
- Bugfix: Clear ReadOnly attribute on file copy when creating
  new Tracking forms or Supervision forms. (Better compatibilty with NextCloud)

## [1.3.2] - 2018-01-22
### Changed
- This version contains numerous changes to improve compatibility with
  folder sharing systems like Nextcloud / Owncloud. In particular,
  working folders have unique names (using the system user name)
  and there can be multiple charts folders.
- This version follows a new naming convention for working folders. Previously,
  the working folder had a static name defined in the configuration. In this
  version, working folders are suffixed with the logged in user's name.
- There is no longer a "Home Visitors" folder for other user's working folders.
  All working folders can be mixed together in the $rootPath
- Multiple charts folder can exist in $rootPath, prefixed by "Charts."

## [1.2.24] - 2017-12-11
This is the first tagged release.
