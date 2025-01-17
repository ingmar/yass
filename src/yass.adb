--    Copyright 2019 Bartek thindil Jasicki
--
--    This file is part of YASS.
--
--    YASS is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    YASS is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with YASS.  If not, see <http://www.gnu.org/licenses/>.

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Directories; use Ada.Directories;
with Ada.Calendar; use Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Environment_Variables; use Ada.Environment_Variables;
with GNAT.Traceback.Symbolic; use GNAT.Traceback.Symbolic;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with AWS.Net;
with AWS.Server;
with Config; use Config;
with Layouts; use Layouts;
with Pages; use Pages;
with Server; use Server;
with Modules; use Modules;
with Sitemaps; use Sitemaps;
with AtomFeed; use AtomFeed;

procedure YASS is
   Version: constant String := "1.1";
   WorkDirectory: Unbounded_String;

   -- Build the site from directory
   -- DirectoryName: full path to the site directory
   -- Returns True if the site was build, otherwise False.
   function BuildSite(DirectoryName: String) return Boolean is
      PageTags: Tags_Container.Map := Tags_Container.Empty_Map;
      PageTableTags: TableTags_Container.Map := TableTags_Container.Empty_Map;
      -- Build the site from directory with full path Name
      procedure Build(Name: String) is
         -- Process file with full path Item: create html pages from markdown files or copy any other file.
         procedure ProcessFiles(Item: Directory_Entry_Type) is
         begin
            if YassConfig.ExcludedFiles.Find_Index(Simple_Name(Item)) /=
              Excluded_Container.No_Index or
              not Ada.Directories.Exists(Full_Name(Item)) then
               return;
            end if;
            Set("YASSFILE", Full_Name(Item));
            if Extension(Simple_Name(Item)) = "md" then
               CreatePage(Full_Name(Item), Name);
            else
               CopyFile(Full_Name(Item), Name);
            end if;
         end ProcessFiles;
         -- Go recursive with directory with full path Item.
         procedure ProcessDirectories(Item: Directory_Entry_Type) is
         begin
            if YassConfig.ExcludedFiles.Find_Index(Simple_Name(Item)) =
              Excluded_Container.No_Index and
              Ada.Directories.Exists(Full_Name(Item)) then
               Build(Full_Name(Item));
            end if;
         exception
            when Ada.Directories.Name_Error =>
               null;
         end ProcessDirectories;
      begin
         Search
           (Name, "", (Directory => False, others => True),
            ProcessFiles'Access);
         Search
           (Name, "", (Directory => True, others => False),
            ProcessDirectories'Access);
      end Build;
   begin
      -- Load the program modules with 'start' hook
      LoadModules("start", PageTags, PageTableTags);
      -- Load data from exisiting sitemap or create new set of data or nothing if sitemap generation is disabled
      StartSitemap;
      -- Load data from existing atom feed or create new set of data or nothing if atom feed generation is disabled
      StartAtomFeed;
      -- Build the site
      Build(DirectoryName);
      -- Save atom feed to file or nothing if atom feed generation is disabled
      SaveAtomFeed;
      -- Save sitemap to file or nothing if sitemap generation is disabled
      SaveSitemap;
      -- Load the program modules with 'end' hook
      LoadModules("end", PageTags, PageTableTags);
      return True;
   exception
      when GenerateSiteException =>
         return False;
   end BuildSite;

   -- Validate arguments which user was entered when started the program and set WorkDirectory for the program.
   -- Message: part of message to show when user does not entered the site project directory
   -- Exist: did selected directory should be test did it exist or not
   -- Returns True if entered arguments are valid, otherwise False.
   function ValidArguments(Message: String; Exist: Boolean) return Boolean is
   begin
      -- User does not entered name of the site project directory
      if Argument_Count < 2 then
         Put_Line("Please specify directory name " & Message);
         return False;
      end if;
      -- Assign WorkDirectory
      if Index(Argument(2), Containing_Directory(Current_Directory)) = 1 then
         WorkDirectory := To_Unbounded_String(Argument(2));
      else
         WorkDirectory :=
           To_Unbounded_String
             (Current_Directory & Dir_Separator & Argument(2));
      end if;
      -- Check if selected directory exist, if not, return False
      if Ada.Directories.Exists(To_String(WorkDirectory)) = Exist then
         if not Exist then
            Put_Line
              ("Directory with that name not exists, please specify existing site directory.");
         else
            Put_Line
              ("Directory with that name exists, please specify another.");
         end if;
         return False;
      end if;
      -- Check if selected directory is valid the program site project directory. Return False if not.
      if not Exist and
        not Ada.Directories.Exists
          (To_String(WorkDirectory) & Dir_Separator & "site.cfg") then
         Put_Line
           ("Selected directory don't have file ""site.cfg"". Please specify proper directory.");
         return False;
      end if;
      return True;
   end ValidArguments;

begin
   if Ada.Environment_Variables.Exists("YASSDIR") then
      Set_Directory(Value("YASSDIR"));
   end if;
   -- No arguments or help: show available commands
   if Argument_Count < 1 or else Argument(1) = "help" then
      Put_Line("Possible actions:");
      Put_Line("help - show this screen and exit");
      Put_Line("version - show the program version and exit");
      Put_Line("license - show short info about the program license");
      Put_Line("readme - show content of README file");
      Put_Line("create [name] - create new site in ""name"" directory");
      Put_Line("build [name] - build site in ""name"" directory");
      Put_Line
        ("server [name] - start simple HTTP server in ""name"" directory and auto rebuild site if needed.");
      Put_Line
        ("createfile [name] - create new empty markdown file with ""name""");
      -- Show version information
   elsif Argument(1) = "version" then
      Put_Line("Version: " & Version);
      Put_Line("Released: 2019-10-23");
      -- Show license information
   elsif Argument(1) = "license" then
      Put_Line("Copyright (C) 2019 Bartek thindil Jasicki");
      New_Line;
      Put_Line
        ("This program is free software: you can redistribute it and/or modify");
      Put_Line
        ("it under the terms of the GNU General Public License as published by");
      Put_Line
        ("the Free Software Foundation, either version 3 of the License, or");
      Put_Line("(at your option) any later version.");
      New_Line;
      Put_Line
        ("This program is distributed in the hope that it will be useful,");
      Put_Line
        ("but WITHOUT ANY WARRANTY; without even the implied warranty of");
      Put_Line
        ("MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the");
      Put_Line("GNU General Public License for more details.");
      New_Line;
      Put_Line
        ("You should have received a copy of the GNU General Public License");
      Put_Line
        ("along with this program.  If not, see <https://www.gnu.org/licenses/>.");
      -- Show README.md file
   elsif Argument(1) = "readme" then
      declare
         ReadmeName: Unbounded_String;
         ReadmeFile: File_Type;
      begin
         if Ada.Environment_Variables.Exists(("APPDIR")) then
            ReadmeName :=
              To_Unbounded_String
                (Value("APPDIR") & "/usr/share/doc/yass/README.md");
         else
            ReadmeName :=
              To_Unbounded_String
                (Containing_Directory(Command_Name) & Dir_Separator &
                 "README.md");
         end if;
         if not Ada.Directories.Exists(To_String(ReadmeName)) then
            Put_Line("Can't find file " & To_String(ReadmeName));
            return;
         end if;
         Open(ReadmeFile, In_File, To_String(ReadmeName));
         while not End_Of_File(ReadmeFile) loop
            Put_Line(Get_Line(ReadmeFile));
         end loop;
         Close(ReadmeFile);
      end;
      -- Create new, selected site project directory
   elsif Argument(1) = "create" then
      if not ValidArguments("where new page will be created.", True) then
         return;
      end if;
      declare
         Paths: constant array(Positive range <>) of Unbounded_String :=
           (To_Unbounded_String("_layouts"), To_Unbounded_String("_output"),
            To_Unbounded_String("_modules" & Dir_Separator & "start"),
            To_Unbounded_String("_modules" & Dir_Separator & "pre"),
            To_Unbounded_String("_modules" & Dir_Separator & "post"),
            To_Unbounded_String("_modules" & Dir_Separator & "end"));
      begin
         for I in Paths'Range loop
            Create_Path
              (To_String(WorkDirectory) & Dir_Separator & To_String(Paths(I)));
         end loop;
      end;
      CreateConfig(To_String(WorkDirectory));
      CreateLayout(To_String(WorkDirectory));
      CreateDirectoryLayout(To_String(WorkDirectory));
      CreateEmptyFile(To_String(WorkDirectory));
      Put_Line
        ("New page in directory """ & Argument(2) & """ was created. Edit """ &
         Argument(2) & Dir_Separator &
         "site.cfg"" file to set data for your new site.");
      -- Build existing site project from selected directory
   elsif Argument(1) = "build" then
      if not ValidArguments("from where page will be created.", False) then
         return;
      end if;
      ParseConfig(To_String(WorkDirectory));
      if BuildSite(To_String(WorkDirectory)) then
         Put_Line("Site was build.");
      else
         Put_Line("Site building has been interrupted.");
      end if;
      -- Start server to monitor changes in selected site project
   elsif Argument(1) = "server" then
      if not ValidArguments("from where site will be served.", False) then
         return;
      end if;
      ParseConfig(To_String(WorkDirectory));
      Set_Directory(To_String(YassConfig.OutputDirectory));
      if YassConfig.ServerEnabled then
         if not Ada.Directories.Exists
             (To_String(YassConfig.LayoutsDirectory) & Dir_Separator &
              "directory.html") then
            CreateDirectoryLayout("");
         end if;
         StartServer;
         if YassConfig.BrowserCommand /= To_Unbounded_String("none") then
            declare
               Args: constant Argument_List_Access :=
                 Argument_String_To_List(To_String(YassConfig.BrowserCommand));
            begin
               if not Ada.Directories.Exists(Args(Args'First).all)
                 or else
                   Non_Blocking_Spawn
                     (Args(Args'First).all,
                      Args(Args'First + 1 .. Args'Last)) =
                   Invalid_Pid then
                  Put_Line
                    ("Can't start web browser. Please check your site configuration did it have proper value for ""BrowserCommand"" setting.");
                  ShutdownServer;
                  return;
               end if;
            end;
         end if;
      else
         Put_Line("Started monitoring site changes. Press ""Q"" for quit.");
      end if;
      MonitorSite.Start;
      MonitorConfig.Start;
      AWS.Server.Wait(AWS.Server.Q_Key_Pressed);
      if YassConfig.ServerEnabled then
         ShutdownServer;
      else
         Put("Stopping monitoring site changes...");
      end if;
      abort MonitorSite;
      abort MonitorConfig;
      Put_Line("done.");
      -- Create new empty markdown file with selected name
   elsif Argument(1) = "createfile" then
      if Argument_Count < 2 then
         Put_Line("Please specify name of file to create.");
         return;
      end if;
      if Index(Argument(2), Containing_Directory(Current_Directory)) = 1 then
         WorkDirectory := To_Unbounded_String(Argument(2));
      else
         WorkDirectory :=
           To_Unbounded_String
             (Current_Directory & Dir_Separator & Argument(2));
      end if;
      if Extension(To_String(WorkDirectory)) /= "md" then
         WorkDirectory := WorkDirectory & To_Unbounded_String(".md");
      end if;
      if Ada.Directories.Exists(To_String(WorkDirectory)) then
         Put_Line
           ("Can't create file """ & To_String(WorkDirectory) &
            """. File with that name exists.");
         return;
      end if;
      Create_Path(Containing_Directory(To_String(WorkDirectory)));
      CreateEmptyFile(To_String(WorkDirectory));
      Put_Line("Empty file """ & To_String(WorkDirectory) & """ was created.");
      -- Unknown command entered
   else
      Put_Line
        ("Unknown command. Please enter ""help"" as argument for program to get full list of available commands.");
   end if;
exception
   when An_Exception : InvalidConfigData =>
      Put_Line
        ("Invalid data in site config file ""site.cfg"". Invalid line:""" &
         Exception_Message(An_Exception) & """");
   when AWS.Net.Socket_Error =>
      Put_Line
        ("Can't start program in server mode. Probably another program is using this same port, or you have still connected old instance of the program in your browser. Please close whole browser and try run the program again. If problem will persist, try to change port for the server in the site configuration.");
   when An_Exception : others =>
      declare
         ErrorFile: File_Type;
      begin
         if Ada.Directories.Exists("error.log") then
            Open(ErrorFile, Append_File, "error.log");
         else
            Create(ErrorFile, Append_File, "error.log");
         end if;
         Put_Line(ErrorFile, Ada.Calendar.Formatting.Image(Clock));
         Put_Line(ErrorFile, Version);
         Put_Line(ErrorFile, "Exception: " & Exception_Name(An_Exception));
         Put_Line(ErrorFile, "Message: " & Exception_Message(An_Exception));
         Put_Line
           (ErrorFile, "-------------------------------------------------");
         Put(ErrorFile, Symbolic_Traceback(An_Exception));
         Put_Line
           (ErrorFile, "-------------------------------------------------");
         Close(ErrorFile);
         Put_Line
           ("Oops, something bad happen and program crashed. Please, remember what you done before crash and report this problem at https://github.com/yet-another-static-site-generator/yass/issues (or if you prefer, on mail thindil@laeran.pl) and attach (if possible) file 'error.log' (should be in this same directory).");
      end;
end YASS;
