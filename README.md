## Abandoned this mess for a fresh start with my bootstrap and pybootstrap. More success there.

## Overview of `.bashrc` Configuration

This has been copied and modified FOR ME from https://github.com/christitustech/mybash
The `.bashrc` file is a script that runs every time a new terminal session is started in Unix-like operating systems. It is used to configure the shell session, set up aliases, define functions, and more, making the terminal easier to use and more powerful. Below is a summary of the key sections and functionalities defined in the provided `.bashrc` file.

## How to install

```
git clone https://github.com/x0d167/QuickLaunchBash
cd QuickLaunchBash
chmod +x setup.sh
./setup.sh
```

### Initial Setup and System Checks

- **Environment Checks**: The script checks if it is running in an interactive mode and sets up the environment accordingly.
- **System Utilities**: It checks for the presence of utilities like `fastfetch`, `bash-completion`, and system-specific configurations (`/etc/bashrc`).

### Dotfile Management

- **Gnu Stow**: Checks for and installs Stow for dotfile management.
- Modified to not create any config files but to pull my own specific dotfiles repo to set up as I like, then it runs stow.

### Aliases and Functions

- **Aliases**: Shortcuts for common commands are set up to enhance productivity. For example, `alias cp='cp -i'` makes the `cp` command interactive, asking for confirmation before overwriting files.
- **Functions**: Custom functions for complex operations like `extract()` for extracting various archive types, and `cpp()` for copying files with a progress bar.

### Prompt Customization and History Management

- **Prompt Command**: The `PROMPT_COMMAND` variable is set to automatically save the command history after each command.
- **History Control**: Settings to manage the size of the history file and how duplicates are handled.

### System-Specific Aliases and Settings

- **Editor Settings**: Sets `nvim` (NeoVim) as the default editor. -- eh, I change this all the time. It might currently favor nvim
- **Conditional Aliases**: Depending on the system type (like Fedora), it sets specific aliases, e.g., replacing `cat` with `bat`.

### Enhancements and Utilities

- **Color and Formatting**: Enhancements for command output readability using colors and formatting for tools like `ls`, `grep`, and `man`.
- **Navigation Shortcuts**: Aliases to simplify directory navigation, e.g., `alias ..='cd ..'` to go up one directory.
- **Safety Features**: Aliases for safer file operations, like using `trash` instead of `rm` for deleting files, to prevent accidental data loss.
- **Extensive Zoxide support**: Easily navigate with `z`, `zi`, or pressing Ctrl+f to launch zi to see frequently used navigation directories.

### Advanced Functions

- **System Information**: Functions to display system information like `distribution()` to identify the Linux distribution.
- **Networking Utilities**: Tools to check internal and external IP addresses.
- **Resource Monitoring**: Commands to monitor system resources like disk usage and open ports.

### Installation and Configuration Helpers

- **Auto-Install**: A function `install_bashrc_support()` to automatically install necessary utilities based on the system type.
- **Configuration Editors**: Functions to edit important configuration files directly, e.g., `apacheconfig()` for Apache server configurations.

### Conclusion

This `.bashrc` file is a comprehensive setup that enhances the experience for me. If you want something more general, use mybash by Chris Titus.
