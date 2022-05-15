# smartdiff
Bash script for easy review through multiple commits

## Installation

To install or update smartdiff, you should run the install script. To do that, you may either download and run the script manually, or use the following cURL or Wget command:

```bash
curl -o- https://raw.githubusercontent.com/dgilan/smartdiff/v0.2.5/install.sh | bash
```

```bash
wget -qO- https://raw.githubusercontent.com/dgilan/smartdiff/v0.2.5/install.sh | bash
```

## Usage

### Start

```bash
smartdiff --filter <branch_prefix>
```

### Continue after resolving the conflicts

```bash
smartdiff --continue
```

### Abort and restore the original state

```bash
smartdiff --abort
```

## Development

### How to release

```bash
# Example
./release.sh 0.0.1 'Description'
```