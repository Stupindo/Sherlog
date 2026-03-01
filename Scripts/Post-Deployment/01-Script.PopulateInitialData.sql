/*
  This post-deployment script combines scripts that populate intial data into dictionary tables;
*/

:r .\logging.Application.data.sql
:r .\logging.Level.data.sql
:r .\logging.Settings.data.sql
:r .\logging.Versions.data.sql