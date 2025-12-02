## Key Features of the Enhanced `lsgroups` Tool:

### **1. Beautiful Colorized Interface**
- Gradient headers and separators
- Status indicators with emoji-like symbols
- Color-coded output for different information types

### **2. Multiple Display Modes**
- `-m, --my`: Current user (default)
- `-u <user>`: Specific user
- `-a, --all`: All users
- `-l, --list`: All system groups
- `-g <group>`: Group members listing

### **3. Enhanced Information**
- **User Details**: UID, GID, home directory, shell
- **Group Details**: GID, member lists, primary group identification
- **Permission Analysis**: Group-writable files, security warnings
- **System Integration**: Works with `/etc/passwd`, `/etc/group`, `getent`

### **4. Output Formats**
- `-c, --compact`: Simple list for scripting
- `-t, --table`: Table format
- `-d, --details`: Verbose group information
- `-v, --verbose`: Maximum details

### **5. Sorting Options**
- Sort by: name (default), id, or user
- Intelligent sorting for different display modes

### **6. Security Features**
- Highlights primary groups
- Shows group-writable files in `/etc`
- Permission warnings for sensitive files

### **7. Professional Features**
- Proper error handling with color-coded messages
- Help system with examples
- Terminal detection for automatic color disabling
- Progress indicators for large operations
- Root privilege detection for advanced features

### **8. Usage Examples:**
```bash
# Basic usage
lsgroups
lsgroups -h

# Different display modes
lsgroups -a              # All users
lsgroups -u alice        # Specific user
lsgroups -g sudo         # Group members
lsgroups -l              # All system groups

# Formatting options
lsgroups -t              # Table format
lsgroups -c              # Compact output
lsgroups -d -i           # Detailed with IDs
lsgroups -p              # Show permission info

# Combined usage
lsgroups -a -s id -t     # All users sorted by ID in table
lsgroups -u root -p -v   # Root user with permissions (verbose)
```

### **Installation:**
```bash
wget https://github.com/stefan-hacks/lsgroups/blob/main/lsgroups.sh

# Make it executable
chmod +x lsgroups.sh

# Optionally, move to system PATH
sudo cp lsgroups.sh /usr/local/bin/lsgroups

# Add completion and source in your bash profile
source lsgroups-completion.bash
```

```bash
#!/usr/bin/env bash
# lsgroups-completion.bash

_lsgroups_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="-h --help -a --all -c --compact -d --details -g --group -i --id -l --list -m --my -n --no-color -p --permissions -s --sort -t --table -u --user -v --verbose"
    
    case "${prev}" in
        -g|--group)
            # Complete group names
            local groups=$(getent group | cut -d: -f1)
            COMPREPLY=( $(compgen -W "${groups}" -- ${cur}) )
            return 0
            ;;
        -u|--user)
            # Complete usernames
            local users=$(getent passwd | cut -d: -f1)
            COMPREPLY=( $(compgen -W "${users}" -- ${cur}) )
            return 0
            ;;
        -s|--sort)
            # Complete sort fields
            COMPREPLY=( $(compgen -W "name id user" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac
    
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _lsgroups_completion lsgroups

```
```
```
This tool provides a professional, feature-rich alternative to basic group listing commands with beautiful formatting, comprehensive information, and security insights suitable for system administrators and power users.
