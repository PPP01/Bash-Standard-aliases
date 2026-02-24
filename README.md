# Bash Standard Aliases

English docs. German variant: `README.de.md`.

## 1. Overview
`bash-standard-aliases` is a modular alias set for Linux servers.
Goal: make recurring admin and development tasks faster, consistent, and easier to audit.

Typical examples:
- Navigation and file views: `ll`, `la`, `..`, `dfh`, `duh`
- Processes and network: `psmem`, `pscpu`, `ports`, `myip`
- Git workflow: `gs`, `ga`, `gcm`, `gpl`
- System services/logs (root): `start nginx`, `status ssh`, `logs nginx`
- Self-management: `_alias_init`, `_alias_setup_language`, `_alias_category_setup`, `_alias_update`, `_alias_edit`

## 2. Install
```bash
git clone https://github.com/PPP01/Bash-Standard-aliases bash-standard-aliases
```

### 2.1 Load directly
```bash
source bash-standard-aliases/bash_alias_std.sh
```

### 2.2 First initialization (`_alias_init`)
```bash
_alias_init
```

This writes a marker-based loader block into your shell startup file and then enters setup.

### 2.2.1 Integration behavior
- Adds marker-based `source` block (idempotent).
- User: target is detected alias file from `~/.bashrc`, otherwise `~/.bashrc`.
- Root: choose between user target and `/etc/bash.bashrc`.

### 2.2.2 Remove integration (`_alias_init_remove`)
```bash
_alias_init_remove
```

## 3. Guided setup (`_alias_setup`)
`_alias_setup` starts a guided three-step flow:
1. Set language
2. Set color scheme
3. Configure categories

```bash
_alias_setup
```

### 3.1 Enable/disable categories only
```bash
_alias_category_setup
```

Where changes are stored:
- Regular user: `~/.config/bash-standard-aliases/config.conf`
- Root: choose `global` (`${BASH_ALIAS_REPO_DIR}/alias_files.local.conf`) or `root-only` (`~/.config/bash-standard-aliases/config.conf`)

Only delta changes are written (deviations), not full base files.

## 4. Usage

### 4.1 Menu `a`
```bash
a
```

Opens an interactive menu with visible categories and alias details.
Disabled categories are shown grayed out below `setup`.
Other categories without available aliases for the current user are hidden.
In details view, `Enter` runs the selected alias directly.

Navigation keys in interactive menus:
- `Up` / `Down`: move selection
- `Right` / `Enter`: open selected item (or run in detail view)
- `Left` / `Backspace` / `0`: go back one level
- `q` / `Esc`: quit menu

### 4.1.1 `a [category]`
```bash
a git
a network
a all
```

- `a <category>` shows aliases in one category.
- `a all` shows all visible categories.

### 4.1.2 `a [alias]`
```bash
a gs
a _alias_init
```

If the parameter is an alias name, `a` opens details directly (description + command).

### 4.1.3 Performance cache for `a`
The `a` menu cache is lazy-built:
- First `a` call computes the cache.
- Then a user-specific disk cache is used:
  - `${XDG_CACHE_HOME:-$HOME/.cache}/bash-standard-aliases`
- On new repo versions the cache is rebuilt automatically.
  - Version detection via git revision (`HEAD`, with `-dirty` if local changes exist).
- User-specific files are part of the cache key:
  - `~/.bash_aliases_specific`
  - `~/.bash_aliases_specific.md`

Disable (optional):
```bash
export BASH_ALIAS_MENU_DISK_CACHE=0
```

### 4.1.4 Menu and detail colors
Colors for menu and detail output are configurable via `BASH_ALIAS_HELP_COLOR_*`
(for example `..._DETAIL_LABEL`, `..._MENU_TITLE`, `..._MENU_HIGHLIGHT_LINE`).
Override via settings layers:

```bash
# global delta (root/host)
settings.local.conf

# user delta
~/.config/bash-standard-aliases/settings.conf
```

### 4.2 Running aliases
Aliases are standard shell aliases/functions and run directly, e.g.:

```bash
ll
gs
ports
```

Root-only modules (e.g. `journald`, `apt`, `systemd`) are only shown/usable if those aliases are available in the current shell.

### 4.3 Add custom aliases

#### 4.3.1 Via menu
```bash
_alias_edit
```

The wizard asks for alias name, description, and command, then reloads automatically.

#### 4.3.2 Storage (+ markdown)
Default storage:
- User: `~/.bash_aliases_specific`
- Root: choose between `~/.bash_aliases_specific` (root-only) and `${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific` (project-wide)

Related help file is stored next to it:
- `~/.bash_aliases_specific.md`
- `${BASH_ALIAS_REPO_DIR}/.bash_aliases_specific.md`

## 5. Update via `_alias_update`
```bash
_alias_update
```

Runs `git pull --ff-only` in repo and reloads afterwards.

Optional:
```bash
_alias_update --restart
```

Starts a fresh login shell after update.

## 6. Localization
Set language with `BASH_ALIAS_LOCALE`:

```bash
export BASH_ALIAS_LOCALE=en
# or
export BASH_ALIAS_LOCALE=de
```

Interactive user settings helper:
```bash
_alias_setup_language
```

Scope:
- Runtime messages and interactive prompts in scripts
- Help/menu texts in `a`
- Errors and status messages in loader/helpers

## 7. Manual configuration
### 7.1 Module config
Config layers for modules (in this order):
1. `alias_files.conf` (base, versioned)
2. `alias_files.local.conf` (global delta changes)
3. `~/.config/bash-standard-aliases/config.conf` (user delta changes)

Per module line:
- Enabled: `20-files.sh`
- Disabled: `# 20-files.sh`

Example (delta only):
```text
# enable
85-mysql.sh

# disable
# 35-git.sh
```

### 7.2 Settings config
Settings layers (in this order):
1. `settings.conf` (base, versioned)
2. `settings.local.conf` (global delta settings)
3. `~/.config/bash-standard-aliases/settings.conf` (user delta settings)

`_alias_setup_scheme` writes two marker blocks into the user settings file:
- `# >>> _alias_setup_scheme managed >>>`: generated scheme values
- `# >>> _alias_setup_scheme user-overrides >>>`: your active manual overrides

Important behavior:
- Active `BASH_ALIAS_HELP_COLOR_*` lines outside the managed block are normalized
  into the `user-overrides` block on the next `_alias_setup_scheme` run.
- This ensures manual color overrides are not shadowed by generated managed values.

Example (delta only):
```bash
# ~/.config/bash-standard-aliases/settings.conf
BASH_ALIAS_HELP_COLOR_DETAIL_LABEL='\033[1;32m'
```

## 8. Manual loader integration
If you do not want `_alias_init`, source the loader directly:

```bash
if [ -f /path/to/bash-standard-aliases/bash_alias_std.sh ]; then
  source /path/to/bash-standard-aliases/bash_alias_std.sh
fi
```

### 8.1 Optional loader profiling
For startup-time analysis, loader timings can be printed per module:

```bash
BASH_ALIAS_PROFILE=1 source /path/to/bash-standard-aliases/bash_alias_std.sh
```

Optional filtering:
```bash
BASH_ALIAS_PROFILE=1 BASH_ALIAS_PROFILE_MIN_MS=20 source /path/to/bash-standard-aliases/bash_alias_std.sh
```

- `BASH_ALIAS_PROFILE=1`: enable profiling
- `BASH_ALIAS_PROFILE_MIN_MS=<n>`: show only modules with at least `<n>` ms
- output goes to `stderr` and includes total runtime

## 9. Structure
- `bash_alias_std.sh`: loader (layer logic + runtime category mapping)
- `alias_files/`: alias modules
- `alias_files.conf`: base config
- `alias_files.local.conf`: global delta config
- `settings.conf`: base settings (e.g. colors)
- `settings.local.conf`: global delta settings
- `scripts/`: setup/marker/category setup logic
- `scripts/alias_category_setup.sh`: category toggling
- `alias_categories.sh`: module <-> category mapping
- `docs/alias_files/*.md`: module docs

## 10. Add your own category (all steps)
1. Create a new module, e.g. `alias_files/45-monitoring.sh`.
2. Define aliases/functions in that module.
3. Add the category in `alias_categories.sh`.
4. Add the category name in `alias_categories_list`.
5. Define sort order in `alias_category_sort_key`.
6. Map module to category in `alias_category_for_module`.
7. Maintain reverse mapping in `alias_modules_for_category`.
8. Optional docs: `docs/alias_files/45-monitoring.md`.
9. Enable module globally (`alias_files.local.conf`) or user-specific (`~/.config/bash-standard-aliases/config.conf`).
10. Reload:
```bash
_alias_reload
```
11. Verify result:
```bash
a monitoring
```
12. Optional consistency test:
```bash
_alias_test_reload
```
