# Redmine GTT Print Plugin

The Geo-Task-Tracker (GTT) print plugin adds printing support issues:

- Supports [Mapfish Print](https://github.com/mapfish/mapfish-print) 
- Complex print layouts with Jasper Reports
- Prints map layers and images (issue attachments)
- and more ...

## Project health

[TBD]

## Requirements

Redmine GTT Print **requires PostgreSQL/PostGIS** and will not work with SQLite or MariaDB/MySQL!!!
It also requires an installation of [Mapfish Print](https://github.com/mapfish/mapfish-print) .

- Redmine >= 3.4.0
- Mapfish Print >= 3.0.0
- [redmine_gtt](https://github.com/gtt-project/redmine_gtt/) plugin

## Installation

To install Redmine GTT Print plugin, download or clone this repository in your Redmine installation plugins directory!

```
cd path/to/plugin/directory
git clone https://github.com/gtt-project/redmine_gtt_print.git
```

Then run

```
bundle install
bundle exec rake redmine:plugins:migrate
```

After restarting Redmine, you should be able to see the Redmine GTT plugin in the Plugins page.

More information on installing (and uninstalling) Redmine plugins can be found here: http://www.redmine.org/wiki/redmine/Plugins

## How to use

[Settings, screenshots, etc.]

## Contributing and Support

The GTT Project appreciates any [contributions](https://github.com/gtt-project/.github/blob/main/CONTRIBUTING.md)! Feel free to contact us for [reporting problems and support](https://github.com/gtt-project/.github/blob/main/CONTRIBUTING.md).

## Version History

See [all releases](https://github.com/gtt-project/redmine_gtt_print/releases) with release notes.

## Authors

- [Jens Kraemer](https://github.com/jkraemer)
- [Daniel Kastl](https://github.com/dkastl)
- [Thibault Mutabazi](https://github.com/eyewritecode)
- [Ko Nagase](https://github.com/sanak)
- ... [and others](https://github.com/gtt-project/redmine_gtt_print/graphs/contributors)

## LICENSE

This program is free software. See [LICENSE](LICENSE) for more information.

