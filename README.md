# batch-scripts

Some bacth scripts I am using personally.

## Content
Including commands:
* __cdnow__ - _Interactive **cd** command for predefined shortcut paths_
* __cdmk__ - _Interactive **cd** command for marked paths_
* __mkcd__ - _A shortcut command to mark current path_

### cdnow ###
This command shows a list of predefined shorcut paths for you to select, or you can directly pass shortcut in commandline for quick switch.
Use **cdnow -e** to edit the config file to add predefined shortcut path as you need.

Normally, I add current project root path to config file to quickly jump to project I am working on.

**Note:** Using this command will save config on %USERPROFILE%\.config\zqcd\ folder, and create %ZQCD_CDNOW% environment variable.

### cdmk ###
This command can 'mark' a path, then you can quick jump back to marked paths using shortcut or select the shortcut in interactive mode.
Use **mkcd** or **cdmk -a** to mark current path.

You can also use %CDMK[_index_]% to reference the marked path in command line.

Normally, I use it to switch back and forth among several related paths for copying or comparison.

**Note:** Using this command (or mkcd) will save config on %USERPROFILE%\.config\zqcd\ folder, and create %CDMK[]% environment variable array (variable name can be changed).

## Installation
Add the script folder to your __PATH__ environment variable.

## Composer
Sonicfly, a.k.a Zkk

## License
Project is published under FreeBSD license.
