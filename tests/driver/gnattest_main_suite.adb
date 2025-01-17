--  This package has been generated automatically by GNATtest.
--  Do not edit any part of it, see GNATtest documentation for more details.

--  begin read only
with AtomFeed.Test_Data.Tests.Suite;
with Config.Test_Data.Tests.Suite;
with Layouts.Test_Data.Tests.Suite;
with Modules.Test_Data.Tests.Suite;
with Pages.Test_Data.Tests.Suite;
with Server.Test_Data.Tests.Suite;
with Sitemaps.Test_Data.Tests.Suite;

package body Gnattest_Main_Suite is

   Result : aliased AUnit.Test_Suites.Test_Suite;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin

      Result.Add_Test (AtomFeed.Test_Data.Tests.Suite.Suite);
      Result.Add_Test (Config.Test_Data.Tests.Suite.Suite);
      Result.Add_Test (Layouts.Test_Data.Tests.Suite.Suite);
      Result.Add_Test (Modules.Test_Data.Tests.Suite.Suite);
      Result.Add_Test (Pages.Test_Data.Tests.Suite.Suite);
      Result.Add_Test (Server.Test_Data.Tests.Suite.Suite);
      Result.Add_Test (Sitemaps.Test_Data.Tests.Suite.Suite);

      return Result'Access;

   end Suite;

end Gnattest_Main_Suite;
--  end read only
