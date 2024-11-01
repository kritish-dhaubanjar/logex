# logex
Bash script to log and organize git-logs by date & repository.

#### Install:
```shell
sudo curl -L https://raw.githubusercontent.com/kritish-dhaubanjar/logex/main/logex.sh -o /usr/local/bin/logex && sudo chmod +x /usr/local/bin/logex
```

Depends on:
- `git config user.name`

#### Uninstall:
```shell
sudo rm /usr/local/bin/logex
```

#### Usage:
```
$ logex --help
Usage: logex [OPTION]... [FILE]
logex - Bash script to log and organize git-logs by date & repository.

Options:
  -d, --days       set number of days to log
  -a, --author     set commit author to log (git config user.name)
  -v, --version    print logex version
  -u, --update     update logex
  -h, --help       display this help and exit
```

#### Tests:

Install Bats if not already installed

```
sudo apt-get install bats  # For Debian-based systems
# or
brew install bats-core      # For macOS
```

#### Preview:

![logex](https://github.com/kritish-dhaubanjar/logex/assets/25634165/728eec62-88ed-41d9-9a95-3cd9f36b664f)
