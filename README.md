# MonkeyBusiness

This gem contains the SurveyMonkey import worker, for use in RunKeeper ETL.  This code can operate independently of other code in the existing ETL codebase; as such, you can run this just as well from your workstation as from the production ETL system.

This gem is not published in public gem repositories; if you want to use it in your code, getting it there is your business.

## Prerequisites

This worker requires the following:

1. SurveyMonkey [API credentials](https://developer.surveymonkey.com/)
2. AWS credentials with access to the SessionSense exports bucket
3. Network access to production Redshift

The worker is configured via environment variables.  The file `dotenv-sample` contains a listing of all the variables that must be set in order for the worker to run; there are doubtless other variables that also affect its operation.

## Installation

__NOTE__ You will have to install the appropriate DB driver for your platform!

### Standalone

From your local Git repository, run `bin/setup` to install the gem's dependencies and see a sample application configuration.  Write this configuration in `.env` in the top level of the repository.

Install the `sequel_pg` gem (`gem install sequel_pg`) and configure `REDSHIFT_DRIVER=postgres`.

### Docker

Alternately, you can build a Docker image from the provided Dockerfile.  Once you have a functional Docker environment (instructions for building one are beyond the scope of this document), run

    $ docker build -t monkeybusiness .

This will create a Docker image called "monkeybusiness" in your environment, with all prerequisites installed.  **NOTE**: make sure that you have populated your `.env` file with your credentials before you build the image!  These credentials will be hard-coded into the image; don't push the image to a public repository.

### Ruby

Add this line to your application's Gemfile:

```ruby
gem 'monkeybusiness'
gem 'sequel_pg', '~> 1.6'
```

Again, since this Gem is not public, you'll have to install it yourself.  `rake install` from the top level of the Git repository will do the trick.

Make sure to configure `REDSHIFT_DRIVER=postgres`.

### Scala

Install the `jdbc-postgresql` gem (`gem install jdbc-postgresql`) and configure `REDSHIFT_DRIVER=jdbc:postgresql`.

TODO: figure this out

## Usage

### Standalone

Run `bin/console` to get an interactive prompt; you can then invoke the runner as documented in the Ruby section below.

    $ ./bin/console

    Frame number: 0/0
    [1] pry(main)>

### Docker

Alternately, if you have built the Docker image as documented above, run

    $ docker run -it --name monkeybusiness-console monkeybusiness
    [1] pry(main)>

This will create a Docker container called "monkeybusiness-console" based on the "monkeybusiness" container you created earlier, and drop you into an interactive console.

### Ruby

The gem's namespace is `MonkeyBusiness`; for convenience, there's a class method `run` that takes a SurveyMonkey survey ID:

```ruby
MonkeyBusiness.run('12345678')
```

Beware of running too many workers concurrently; SurveyMonkey imposes a limit on the number of API calls per second that varies depending on your account tier, and the `surveymonkey` client gem is not smart enough to keep track of how close you are to the limit.

### Scala

TODO: figure this out
