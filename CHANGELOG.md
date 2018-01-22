# Changelog for HANDS box
Notable changes to HANDS Box at each version

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
