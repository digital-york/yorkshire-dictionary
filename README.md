# Yorkshire Historic Dictionary

This project is the online version of the Yorkshire Historic Dictionary. Development is scheduled to continue until the end of August 2018.

For more information on the wider project, please see [this link](https://www.york.ac.uk/borthwick/projects/yorkshire-dictionary/).

The project is deployed to heroku for demo purposes, and can be accessed [here](https://yhd.herokuapp.com).

The software is developed in Rails 5, and uses a postgres database.

## Deployment
If you want to deploy the project yourself, you'll need to setup a postgres instance and update `database.yml` to match. The existing DB config expects the following in the credentials file (use `bin/rails credentials:edit` to update):

```
database:
    staging_pw: STAGING DB KEY
```

Production database passwords will be added when a domain name is selected and hosting organised.

Due to the way the managed postgres service at York University works, we have to specify the schema used by postgres explicitly, and the default database is configured to mirror the production config for the most part, which can cause some peculiarities with database access (running tests & running Rails database commands from the command line). These are outlined in the `postgres_issues.md` file. Because of these issues, restoring the database dump can cause issues. If that's the case, you can import the data from the CSV directly. See the following section for more information.

Place names are geocoded, and compares the results from multiple sources to find the best match - so you'll also want an API key for Google & OpenCage geocoding APIs. If you'd prefer to avoid this, you can remove the `after_validation :geocode` line from `place.rb`. This will however result in all maps on the app being empty. To set the two mapping credentials, use `bin/rails credentials:edit` add the following:

```
maps:
    google_api_key: GOOGLE MAPS API KEY
    opencage_api_key: OPENCAGE API KEY

```

## Importing data
_See import_readme.md for more information_

To import the data from `import_files/yhd.csv` into the app, you can run `rails yhd:import` from the command line.

Alternatively, there is a `.dump` file in the `import_files` directory that can be restored to a postgres database directly:

```
pg_restore -d *DATABASE_NAME* --no-privileges --no-owner --clean -U *DATABASE_USER* -n *DATABASE_SCHEMA* -W import_files/*DUMP_NAME*.dump
```

For the original development environment, this amounts to:

```
pg_restore -d yhd_dev --no-privileges --no-owner --clean -U yhd -n yhd -W import_files/dump_270618.dump
```

The schema is specified due to the way the default production environment at the university is configured, and to allow dump compatability across environments.

If you wish to regenerate the CSV from the original XLSX file, please refer to `import_readme.md`.

## Other technologies used
* Leaflet.js - mapping
* Google & OpenCage geocoding services
* vis.js - network graph visualisation
* jquery & jquery-UI