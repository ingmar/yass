## Bugs reporting

Bugs are not only problems or the program crashes, but also typos. If you
find any bug in the program, please report it at
<https://github.com/yet-another-static-site-generator/yass/issues> or if
you prefer, on mail <thindil@laeran.pl>

### Some general hints about reporting bugs

- In "Title" field try write short but not too general description of
  problem. Good example: "The program crash when running command". Bad
  example: "The program crashes often."
- In body/comment field try write that much informations about problem as
  possible. In most cases more informations is better than less. General rule
  of good problem report is give enough informations which allow to reproduce
  problem by other people. It may be in form of steps which are needed for
  cause problem.
- If the program crashed, in most cases it should create file *error.log* in
  current directory. It will be a lot of help if you can attach that file to
  the bug report. Each bug information in this file contains: date when crash
  happens, version of the program used, source code file and line in this
  file. If the program can't  discover source code file, it will write memory
  address instead. You can check this last information by using command
  `addr2line` in directory where *yass* executable file is. Example:

  `addr2line -e yass [here full list of memory addresses from error.log]`

### Example of bug report:

Title: "The program crashed when trying to run command"

Body:

1. Enter in terminal: yass mycommand
2. Press enter
3. The program crashes

## Features propositions

If you want to talk/propose changes in any existing the prorgam feature or
mechanic, feel free to contact me via issues tracker or mail (addresses of
both you can find at top of this file). General rule about propositions is
same as for bugs reports - please, try write that much informations as
possible. This help us all better understand purpose of your changes.

## Code propositions

### General informations

If you want to start help in the program development, please consider starts
from something easy like fixing bugs. Before you been want to add new feature
to the program, please contact with me by issues tracker or mail, addresses
of both are at top of this file. Same as with features proposition - your code
may "collide" with my work and it this moment you may just lost time by
working on it. So it is better that we first discuss your proposition. In any
other case, fell free to fix my code.

### Coding standard

When you write your own code, feel free to use any coding standard you want.
But before you send your changes to the project, please use command `gnatpp`
which automatically format source code to project coding standard. Proper
`gnatpp` command usage (in main project directory, where *yass.gpr* file is):

`gnatpp -P yass.gpr`

#### Code comments formatting

The program uses [ROBODoc](https://rfsber.home.xs4all.nl/Robo/) for generating
code documentation. When you write your own code, please add proper header
documentation to it. If you use Vim/NeoVim, easiest way is to use plugin
[RoboVim](https://github.com/thindil/robovim). Example of documentation
header:

    1 -- ****f* Utils/GetRandom
    2 -- FUNCTION
    3 -- Return random number from Min to Max range
    4 -- PARAMETERS
    5 -- Min - Starting value from which generate random number
    6 -- Max - End value from which generate random number
    7 -- RESULT
    8 -- Random number between Min and Max
    9 -- SOURCE
    10 function GetRandom(Min, Max: Integer) return Integer;
    11 -- ****

1 - Documentation header. Yass uses `-- ****[letter]* [package]/[itemname]`
format for documentation headers.

2-9 - Documentation. For all available options, please refer to ROBODoc
documentation. Yass uses `-- ` for start all documenation lines.

10 - Source code of item.

11 - Documentation footer. Yass uses `-- ****` for closing documentation.

How to generate the code documentation is described in main *README.md* file.

### Code submission

Preferred way to submit your code is clone repository and then open new pull
proposal at <https://github.com/yet-another-static-site-generator/yass/compare>.
But if you prefer, you can send your code by mail too (email address is at
top of this file). In that situation, please append to your mail patch file
with changes.

## Additional debugging options

### Code analysis

To enable check for `gcov` (code coverage) and `gprof` (code profiling) compile
the program with mode `analyze` (in main project directory, where *yass.gpr*
file is):

`gprbuild -P yass.gpr -XMode=analyze`

or, if you have Bob installed, command:

`bob analyze`

More informations about code coverage and profiling, you can find in proper
documentation for both programs.
