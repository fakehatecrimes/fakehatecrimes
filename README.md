## fakehatecrimes

This is a project to create a database of hate crime hoaxes in the USA. It builds on the work of Laird Wilcox, whose 'Crying Wolf' is the only book dedicated to this subject so far. It is hosted at http://fakehatecrimes.org.

To initialize the database, log into the MySQL command program as root

`$ mysql -u root -p`

then

`create database fakehatecrimesdevelopment;`
`use fakehatecrimesdevelopment;`

`GRANT ALL PRIVILEGES ON fakehatecrimesdevelopment TO 'root'@'localhost';`
`GRANT ALL PRIVILEGES ON fakehatecrimesdevelopment.* TO 'root'@'localhost';`

and

`source ./db/database.sql.txt`

Then do the same with database `fakehatecrimestest`

You need to do this before running the tests: `rspec`

