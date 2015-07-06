# Monkeybusiness

This gem contains the SurveyMonkey import worker, for use in RunKeeper ETL.  This code can operate independently of other code in the existing ETL codebase; as such, you can run this just as well from your workstation as from the production ETL system.

This gem is not published in public gem repositories; if you want to use it in your code, getting it there is your business.

## Prerequisites

This worker requires the following:

1. SurveyMonkey [API credentials](https://developer.surveymonkey.com/)
2. AWS credentials with access to the SessionSense exports bucket
3. Network access to production Redshift

The worker is configured via environment variables.  The file `dotenv-sample` contains a listing of all the variables that must be set in order for the worker to run; there are doubtless other variables that also affect its operation.

## Installation

### Standalone

From your local Git repository, run `bin/setup` to install the gem's dependencies and see a sample application configuration.  Write this configuration in `.env` in the top level of the repository.

### Ruby

Add this line to your application's Gemfile:

```ruby
gem 'monkeybusiness'
```

Again, since this Gem is not public, you'll have to install it yourself.  `rake install` from the top level of the Git repository will do the trick.

### Scala

TODO: figure this out

## Usage

### Standalone

Run `bin/console` to get an interactive prompt; you can then invoke the runner as documented in the Ruby section below.

    $ ./bin/console

    Frame number: 0/0
    [1] pry(main)>

### Ruby

The gem's namespace is `MonkeyBusiness`; for convenience, there's a class method `run` that takes a SurveyMonkey survey ID:

```ruby
MonkeyBusiness.run('12345678')
```

Beware of running too many workers concurrently; SurveyMonkey imposes a limit on the number of API calls per second that varies depending on your account tier, and the `surveymonkey` client gem is not smart enough to keep track of how close you are to the limit.

### Scala

TODO: figure this out
