# Yorkshire Historic Dictionary

This project is the online version of the Yorkshire Historic Dictionary. Development is scheduled to continue until the end of August 2018.

For more information on the wider project, please see [this link](https://www.york.ac.uk/borthwick/projects/yorkshire-dictionary/).

The project is currently deployed to heroku for demo purposes, and can be accessed [here](https://yhd.herokuapp.com).

There's also a demo running on UoY infrastructure, available on campus. It can be found [here](https://dlibingdev0.york.ac.uk/).

The app is developed with Rails 5 and uses a Postgres database. Data originates from a large tabbed Excel sheet, which is converted to a CSV and then imported.

Database dumps of the final imported data are available, but due to a number of limitations around our database setup may not be importable into a regular Postgres instance. In that case, a Rake task exists to import the data from the CSV.

## Configuration

### Credentials
There are a number of credentials which should be set to run the app, relating to external services. Credentials can be set using `bin/rails credentials:edit`. It may be impossible to run this command outside of the development/test environment. See the note at the end of this document for more information on this issue, and how to solve it.

For a guide on how encrypted credentials functions, see the following URL: 

https://edgeguides.rubyonrails.org/security.html#custom-credentials

You can use the following template if recreating the credentials file:

```
maps:
    google_api_key: 'key'
    opencage_api_key: 'key'

# Used in database.yml for staging server
database:
    staging_pw: 'password'

# Must be a gmail-based email address, with default mailer setup
mailer:
    user_name: 'example@york.ac.uk'
    password: 'password'

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: abcd1234
```

(Use `rails secret` to generate the secret_key_base if it's not already present)

### Email

The mailer is configured to use Gmail (including the York university Google suite email addresses). If you wish to use another mail provider, you can alter the mailer config in `production.rb`. 

You might notice that the mailer SMTP settings are configured in both `environment.rb` and the environment-specific files, such as `heroku.rb`, `staging.rb` and `production.rb`. Ideally, these settings would be defined in `environment.rb` and then only overwritten in the other files as necessary (only `heroku.rb` would need to overwrite). However, an issue with the setting `eager_load=true` in environments that use that setting causes the SMTP settings to be lost, and hence they need to be redefined after calling the eager load line.

See [here](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration) for more information on the available mailer settings.

### Deployment
If you want to deploy the project yourself, you can either use Heroku or configure it to run on a traditional server. 

#### Traditional Server
If deploying traditionally, you'll need to set up a Postgres instance and update `database.yml` to match. The existing DB config is set up for a university server for staging purposes. 

The `database.yml` expects the following in the credentials file to connect to the staging database:

```
database:
    staging_pw: '**password for UoY YHD staging DB**'
```

If deploying to production on a university server, a `production` entry will need to be added to `database.yml` and the credentials added to the credentials file. It is expected this will occur when a domain name is selected and hosting organised. Other than the password & username, it is likely the production config should match the existing staging setup.

Once you've configured the app, it will need uploading to the server. Currently, the University server uses Passenger to serve the app, and everything is configured using Puppet. For more information, speak to Jim Adamson (*jim.adamson {at} york ac uk*). To trigger Passenger to reload the app after an update, you can use the `sudo passenger-config restart-app` command, and select the YHD app from the list.

Before running the app on production or staging, you will also want to precompile the app's assets. For a production environment, you can use the following command:

`RAILS_ENV=production bin/rails assets:precompile`

This compiles the assets into single files where possible. See [here](https://guides.rubyonrails.org/asset_pipeline.html#precompiling-assets) for more information on the process.

In order for the encrypted credentials to be readable, the `RAILS_MASTER_KEY` environment variable needs to be set. The existing value is available in Lastpass under the YHD directory in the 'Shared Digital Library' section. Alternatively, running `bin/rails credentials:edit` without a `master.key` file being present will generate a new one, and you will need to re-set the credentials.

Next, set up the schema with the following command:

`bin/rails db:schema:load`

You can now run the import process with:

`bin/rails yhd:import`

See the 'Importing Data' section for further information on the import process.

#### Heroku
For a heroku deployment, begin by installing the Heroku command line tools. Create a new project using `heroku create --region eu` on the command line in the YHD folder. You can also do this through the Heroku website, but doing so through the command line automatically configures the Git remote server which you will deploy to.  

To use Heroku's Postgres service, you'll need to configure the Postgres add on. Since the free tier of Heroku postgres only supports 10k rows, an upgrade to a higher plan is necessary. The 'hobby basic' plan allows up to 10M rows, and the performance should be adequate. There is more information available [here](https://www.heroku.com/pricing). You can configure the service through the web interface, or by running `heroku addons:create heroku-postgresql:hobby-basic` (notice the 'hobby-basic' plan choice). Further information is available [here](https://devcenter.heroku.com/articles/heroku-postgresql#provisioning-heroku-postgres).

Once you have your project set up with an adequate Postgres plan, the database needs to be linked to the new app. Traditionally, Heroku assumes a 'production' environment name. Since `database.yml` is configured to use 'heroku' as the environment name, you need to update the environment name, or update the database config. So either use the following command to set the Rails environment to 'heroku':

`heroku config:set RACK_ENV=heroku RAILS_ENV=heroku --remote heroku`

Or change the 'heroku' config name in `database.yml` to 'production'.

The database is configured to use the `DATABASE_URL` env. var., and should work out of the box, since heroku will configure this var automatically.

For posterity's sake, the heroku DB configlooks like this:

```
heroku:
    <<: *default
    url: <%= ENV['DATABASE_URL'] %>
```

Set the master key using the following command: ``heroku config:set RAILS_MASTER_KEY=<your-master-key>`

For university staff, the master key used throughout development is available in Lastpass under the YHD directory in the 'Shared Digital Library' section. Alternatively, you can regenerate a new master key and use `bin/rails credentials:edit` to re-set the credentials.

Now, the app should be ready to deploy. In order to do this, simply push to the **master** branch of the Heroku remote Git server. This should have been configured when running `heroku create`, but if not, you can follow the instructions [here](https://devcenter.heroku.com/articles/git#creating-a-heroku-remote). 

Typically, the command looks like this:

`git push heroku`

This pushes the local master branch to the heroku remote master branch. Alternatively, you can use the following to push a specific local branch to heroku's master branch:

`git push heroku local_branch_name:master` (where `local_branch_name` is the local branch name).

For more information on the deployment process, see [here](https://devcenter.heroku.com/articles/git#deploying-code).

Asset precompilation is automatically executed during the push stage if deploying to Heroku, as long as no precompiled assets are included in the app directory. See [here](https://devcenter.heroku.com/articles/rails-asset-pipeline#compiling-assets-during-slug-compilation) for more information.

Once the push is successful, you can set up the data. First of all, set up the schema with the following command:

`heroku run rails db:schema:load`

You can now run the import process with:

`heroku run rails yhd:import`

See the 'Importing Data' section for further information on the import process.

## Importing data
_See `import_readme.md` for more information_

To import the data from `import_files/yhd.csv` into the app, you can run `rails yhd:import` from the command line. It will process each line from the CSV, saving the model objects as it goes. After processing all rows, it will output a list of errors/inconsistencies detected in the data.

### Restoring from database dumps
Due to the way the managed postgres service at York University works, we have to specify the schema used by Postgres explicitly. This schema setup is not typical, and so can cause some peculiarities with accessing the database for certain scenarios (running tests & running Rails database commands from the command line). 

These are outlined in the `postgres_issues.md` file. Because of these issues, restoring the database dump may not be easy, if using a different schema structure (such as a default Postgres installation). If that's the case, it's probably easier to import the data from the CSV directly.

If you do wish to attempt restoring the data, there is a `.dump` file in the `import_files` directory that can be restored to a postgres database directly:

```
pg_restore -d *DATABASE_NAME* --no-privileges --no-owner --clean -U *DATABASE_USER* -n *DATABASE_SCHEMA* -W import_files/* DUMP_NAME*.dump
```

For the original development environment, this amounts to:

```
pg_restore -d yhd_dev --no-privileges --no-owner --clean -U yhd -n yhd -W import_files/dump_xxxxx.dump
```

The schema is specified as it is due to the way the default production environment at the university is configured, and to allow dumps to be restored from development machines to the university servers.

## Geocoding

Place names are geocoded, and the geocoding process compares the results from multiple sources to find the best match. In order for these to run, you'll need an API key for Google & OpenCage geocoding APIs in the credentials file. If you'd prefer to avoid this, you can remove the `after_validation :geocode` line from `place.rb`. This will however result in all maps on the app being empty. To set the two mapping credentials, use `bin/rails credentials:edit` add the following:

```
maps:
    google_api_key: GOOGLE MAPS API KEY
    opencage_api_key: OPENCAGE API KEY
```

By default, the geocode method is run after a model is validated, so usually when it's saved. There is a conditional that checks for places that are already geocoded or don't have a place name to avoid sending too many geocode requests. If you need to run geocoding manually, outside of saving records, you can use the following command. Bear in mind that both APIs will have a request limit (~2500 per day for free tiers at time of writing), so you might hit API rate limits after geocoding a large number of records. In this instance, you'll want to cancel the command and restart it a day later. The conditional will ensure that records aren't geocoded twice.

```
bin/rails geocode:all CLASS=Place Sleep=0
```

## Other technologies used
* Leaflet.js - mapping
* Google & OpenCage geocoding services
* vis.js - network graph visualisation
* jquery & jquery-UI

## Troubleshooting
### Unable to set credentials

Since the `credentials:edit` command loads the environment data before launching, a circular dependency can be introduced if missing credentials are accessed in the environment initialisation process. For example:

`environment.rb` sets the mailer configuration, and therefore uses the mailer credentials. When you run `credentials:edit` without already having the credentials for the mailer, the command will fail to launch since it loads `environment.rb` as it starts.

So, to set the credentials, run the command in the development environment - this will allow the mailer config to be skipped, whereas in other environments it will terminate early. Bear in mind, if mailer credentials aren't included, the mailer won't work in dev/test environments, but the app will still run.