# obfus

## Under development!

> File compression and encryption tool

Obfus utilizes the top notch of both compression and encryption technology, making it easy to pack and back up sensitive data in a few keystrokes.

### Requirements
- [Brotli](https://github.com/google/brotli)
- [GnuPG](https://github.com/gpg/gnupg)

## Install

```bash
brew install obfus
```

## Usage

#### Archive
```bash
obfus readme.md src/*.rb -o backup.obfus
```

#### Unarchive
```bash
obfus -d backup.obfus
```

## Features

### Configuration file
Before each operation, `obfus` searches for a configuration file, usually located in `~/.config/obfus/` or in your home directory.

The config file can be both in `json` or `yaml` format.

Inside the configuration file you can define a list of presets that can be used when `obfus` archives data.

Example configuration file:
```yaml
# ~/.config/obfus/config.yml

default:
  recipients:
    - myself@mail.com
  level: 9
  keep: false

work:
  recipients:
    - coworker@company.com
    - boss@company.com
  level: 3
  keep: true
  verbosity: verbose

backup:
  recipients:
    - myself@mail.com
  level: 11
  verbosity: verbose
```

By default `obfus` uses the `default` preset if present, otherwise it will operate with the program's native defaults.

To specify a preset use the `-p` option:

```bash
obfus -p work ~/Documents/work/
```

The configuration file's sole purpose is to make it easier to pick the settings and apply them on the fly every time you need.
To ovveride the current preset settings or the default settings just pass more options as arguments.

For example, to add a recipient to the archive without altering the config file use the `-r` option:

```bash
obfus -p work ~/Documents/work/ -r mommy@mail.com,daddy@mail.com
```

#### Configuration file location
- `~/.config/obfus/config{,.json,.yaml,.yml}`
- `~/.obfus{rc,config}`

### Options

|Name|Shorthand|Functionality|Default|
|-|-|-|-|
|`--compress`|`-z`|Compress operation mode|yes|
|`--decompress`|`-d`|Decompress operation mode|no|
|`--output FILE`|`-o`|Specify the output file name||
|`--force`|`-f`|Force overwrite the output file if it already exists|`false`|
|`--preset NAME`|`-p`|Use a preset configuration from the config file|`default`|
|`--level [0..9]`|`-l`|Specify the compression level (as in brotli)|`9`|
|`--keep`|`-k`|Keep the original files|`true`|
|`--recipients X,Y,Z`|`-r`|Add recipients||
|`--verbose`|`-v`|Prints more stuff||
|`--quiet`|`-q`|Prints nothing but errors, if any||
|`--version`||Print the version and exit||
|`--help`|`-h`|Print the help message and exit||

> Options can be concatenated, like in many unix programs:
>
> `obfus files/* -vrfo output.obfus`
