# Postgres issues
The following guide documents a few issues possibly faced when setting up a Rails app to use a postgres database managed by IT services. It may be relevant to other deployments also.

## Access to the postgres system database

Many of the standard rails (rake) db tasks internally create a 'master' connection, which uses the `postgres` database (as in, the database called `postgres`, not the database software).

By default, IT services provisions a database with a given name, e.g. `example`. They also remove access to the `postgres` database. 

Tools like `psql` connect to _a_ database. When there are no databases available, such as when a postgres instance is first created, there needs to be a database to connect to. Hence, postgres provides the `postgres` database for tools to make an initial connection to, so that they can create other databases. This is why the rails DB tasks attempt to make contact with that database.

Since IT services remove access to that database (through the `pg_hba.conf` file), many of the database rake tasks will fail (`db:reset`, `db:load` etc.).

As a result, `db:schema` tasks should be used instead, as these appear to work fine and don't attempt to connect to the `postgres` database. The process of connecting to the master database is handled in the following file at the time of writing:

[Github link to rake task](https://github.com/rails/rails/blob/master/activerecord/lib/active_record/tasks/postgresql_database_tasks.rb)

If you really need to run a rake task that gives you the following error (note the **postgres** database name)...

`FATAL: no pg_hba.conf entry for host "…”, user “u…”, database “postgres”, SSL ...`

...then you will need to negotiate access to that database with IT services. Here are two discussions of the database, which seem to suggest that access isn't necessarily a security risk, and an expected part of using Postgres.

* [Link 1](https://dba.stackexchange.com/questions/144285/what-is-the-special-database-postgres-for)
* [Link 2](https://stackoverflow.com/questions/27731111/is-the-postgres-database-always-available-in-postgresql)

## Schema naming

In postgres, a schema is an abstraction that sits between the database and the tables. One database can have multiple schemas, and each schema multiple tables.

On a related note, there is also the concept of a `search path`, which is basically a list of schemas that the current user is allowed access to. Usually, the first schema in this list is `public`. However, IT services also remove access to this schema.

For a typical postgres installation, this `public` schema *will* be accessible. As a result, tables in the database will be added to that schema. This is usually the case when creating a rails app using postgres.

This can cause issues when trying to backup local data to a database dump and subsequently restore it on the IT services managed postgres instance. The database dump will have all the data in the `public` schema, and the restore will be unable to insert them into that same schema on the managed instance. As far as I can tell, there is no way to redirect data to a different schema - only specify which schemas are to be restored.

To work around this, and allow postgres dumps to be shared between environments, you can ask IT services to use a common, non-suffixed schema name. For example, the YHD database always uses the schema name `YHD`, and only the database name varies: `yhd_dev`, `yhd_staging`, `yhd_production` etc. The normal IT services setup would have the schema name as the database name.

The following script was modified from the script IT services uses to set up postgres instances, and can be used to recreate such a setup locally: (pass in the 6 args)

```
#!/bin/sh
db=$1
schema=$2
user=$3
passadmin=$4
passread=$5
passedit=$6
psql postgres -v db=$db -v schema=$schema -v user=$user -v passadmin=$passadmin -v passread=$passread -v passedit=$passedit -v userread=$user'_read' -v useredit=$user'_edit' << EOF
create user :user password '$passadmin';
create database :db owner=:user;
\c :db
revoke create on schema public from public;
revoke create on schema public from :user;
revoke all privileges on database :db from public;
create schema :schema authorization :user;
create user :userread password '$passread';
create user :useredit password '$passedit';
alter role :userread set search_path to :schema;
alter role :useredit set search_path to :schema;
grant usage on schema :schema to :userread;
grant usage on schema :schema to :useredit;
grant connect on database :db to :userread;
grant connect on database :db to :useredit;
alter default privileges for role :user in schema :schema grant select on tables to :userread;
alter default privileges for role :user in schema :schema grant select, insert, update, delete 
on tables to :useredit;
EOF
echo "db: $db"
echo "schema: $schema"
echo "user: $user"
echo "$db (admin): $passadmin"
echo "$db""_read: $passread"
echo "$db""_edit: $passedit"
```
