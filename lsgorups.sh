#!/usr/bin/env bash

# lsgroups - Enhanced group listing tool with colorized output
# Author: SysAdmin Toolkit
# Version: 2.0.0

# Color definitions with fallback for non-color terminals
if [[ -t 1 ]] && [[ -z "${NO_COLOR}" ]] && [[ "${TERM}" != "dumb" ]]; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  WHITE=$(tput setaf 7)
  BOLD=$(tput bold)
  DIM=$(tput dim)
  RESET=$(tput sgr0)
  BG_BLUE=$(tput setab 4)
  BG_GRAY=$(tput setab 8)
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  CYAN=""
  WHITE=""
  BOLD=""
  DIM=""
  RESET=""
  BG_BLUE=""
  BG_GRAY=""
fi

# ASCII art for header
HEADER="
${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}
${BLUE}║${RESET}${BOLD}${CYAN}                    lsgroups v2.0.0${RESET}                      ${BLUE}║${RESET}
${BLUE}║${RESET}${DIM}          Enhanced Group Listing Tool${RESET}                    ${BLUE}║${RESET}
${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}
"

# Function to display help
show_help() {
  echo "${HEADER}"
  echo "${BOLD}${WHITE}DESCRIPTION:${RESET}"
  echo "  ${DIM}Display detailed group information for users in a beautifully formatted output.${RESET}"
  echo ""
  echo "${BOLD}${WHITE}USAGE:${RESET}"
  echo "  ${GREEN}lsgroups${RESET} [${YELLOW}OPTIONS${RESET}] [${YELLOW}USERNAME${RESET}]"
  echo ""
  echo "${BOLD}${WHITE}OPTIONS:${RESET}"
  echo "  ${YELLOW}-h, --help${RESET}             Show this help message"
  echo "  ${YELLOW}-a, --all${RESET}              Show groups for all users (detailed)"
  echo "  ${YELLOW}-c, --compact${RESET}          Show compact output (only group names)"
  echo "  ${YELLOW}-d, --details${RESET}          Show detailed group information"
  echo "  ${YELLOW}-g, --group${RESET} ${MAGENTA}<groupname>${RESET}  Show members of specific group"
  echo "  ${YELLOW}-i, --id${RESET}               Show group IDs alongside names"
  echo "  ${YELLOW}-l, --list${RESET}             List all system groups with IDs"
  echo "  ${YELLOW}-m, --my${RESET}               Show only current user's groups (default)"
  echo "  ${YELLOW}-n, --no-color${RESET}         Disable color output"
  echo "  ${YELLOW}-p, --permissions${RESET}      Show file permissions for group-writable files"
  echo "  ${YELLOW}-s, --sort${RESET} ${MAGENTA}<field>${RESET}       Sort by: name, id, user (default: name)"
  echo "  ${YELLOW}-t, --table${RESET}            Show in table format"
  echo "  ${YELLOW}-u, --user${RESET} ${MAGENTA}<username>${RESET}   Show groups for specific user"
  echo "  ${YELLOW}-v, --verbose${RESET}          Show verbose output"
  echo ""
  echo "${BOLD}${WHITE}EXAMPLES:${RESET}"
  echo "  ${DIM}lsgroups${RESET}                     # Show current user's groups"
  echo "  ${DIM}lsgroups -u alice${RESET}            # Show groups for user 'alice'"
  echo "  ${DIM}lsgroups -a${RESET}                  # Show all users and their groups"
  echo "  ${DIM}lsgroups -g sudo${RESET}             # Show members of 'sudo' group"
  echo "  ${DIM}lsgroups -l${RESET}                  # List all system groups"
  echo "  ${DIM}lsgroups -d -t${RESET}               # Detailed table output"
  echo ""
  echo "${BOLD}${WHITE}NOTES:${RESET}"
  echo "  ${DIM}• Requires root privileges for some operations${RESET}"
  echo "  ${DIM}• Colors are automatically disabled when piping output${RESET}"
  exit 0
}

# Function to check if user exists
user_exists() {
  getent passwd "$1" >/dev/null 2>&1
  return $?
}

# Function to check if group exists
group_exists() {
  getent group "$1" >/dev/null 2>&1
  return $?
}

# Function to get group information
get_group_info() {
  local groupname="$1"
  local line
  line=$(getent group "$groupname" 2>/dev/null)
  [[ -n "$line" ]] && echo "$line"
}

# Function to display group members
show_group_members() {
  local groupname="$1"
  local group_info

  if ! group_info=$(get_group_info "$groupname"); then
    echo "${RED}Error: Group '$groupname' not found${RESET}" >&2
    return 1
  fi

  local group_id=$(echo "$group_info" | cut -d: -f3)
  local members=$(echo "$group_info" | cut -d: -f4)

  echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${WHITE}Group:${RESET} ${GREEN}${groupname}${RESET} ${DIM}(GID: ${group_id})${RESET}"
  echo "${BOLD}${WHITE}Members:${RESET}"

  if [[ -z "$members" ]]; then
    echo "  ${DIM}(no members)${RESET}"
  else
    # Convert comma-separated to list
    echo "$members" | tr ',' '\n' | while read -r member; do
      echo "  • ${GREEN}${member}${RESET}"
    done
  fi

  # Show files owned by this group
  if [[ "$SHOW_PERMISSIONS" == "true" ]] && [[ "$EUID" -eq 0 ]]; then
    echo ""
    echo "${BOLD}${WHITE}Recently modified group-writable files:${RESET}"
    find / -type f -group "$groupname" -perm -g=w 2>/dev/null |
      head -5 | while read -r file; do
      echo "  ${DIM}${file}${RESET}"
    done
  fi

  echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
}

# Function to list all system groups
list_all_groups() {
  echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${WHITE}SYSTEM GROUPS${RESET}"
  echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

  if [[ "$TABLE_FORMAT" == "true" ]]; then
    printf "${BOLD}${WHITE}%-20s %-10s %-30s${RESET}\n" "GROUP" "GID" "MEMBERS"
    echo "${DIM}────────────────────────────────────────────────────────────────────${RESET}"
  fi

  getent group | sort -t: -k3 -n | while IFS=: read -r name pass gid members; do
    if [[ "$TABLE_FORMAT" == "true" ]]; then
      printf "${GREEN}%-20s${RESET} ${YELLOW}%-10s${RESET} ${DIM}%-30s${RESET}\n" \
        "$name" "$gid" "${members:-(none)}"
    elif [[ "$COMPACT" == "true" ]]; then
      echo "$name"
    else
      echo "${GREEN}${name}${RESET} ${DIM}(GID: ${YELLOW}${gid}${RESET})${DIM} → ${members:-(no members)}${RESET}"
    fi
  done

  if [[ "$TABLE_FORMAT" != "true" ]] && [[ "$COMPACT" != "true" ]]; then
    echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo "${DIM}Total: $(getent group | wc -l) groups${RESET}"
  fi
}

# Function to get user's groups with details
get_user_groups() {
  local username="$1"
  local primary_gid
  local user_groups

  if ! user_exists "$username"; then
    echo "${RED}Error: User '$username' not found${RESET}" >&2
    return 1
  fi

  # Get user info
  local user_info=$(getent passwd "$username")
  local uid=$(echo "$user_info" | cut -d: -f3)
  primary_gid=$(echo "$user_info" | cut -d: -f4)
  local home=$(echo "$user_info" | cut -d: -f6)
  local shell=$(echo "$user_info" | cut -d: -f7)

  # Get groups
  user_groups=$(id -nG "$username" 2>/dev/null)

  if [[ "$COMPACT" == "true" ]]; then
    echo "$user_groups" | tr ' ' '\n'
    return
  fi

  # Display header
  echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${WHITE}User:${RESET} ${GREEN}${username}${RESET}"
  echo "${BOLD}${WHITE}UID/GID:${RESET} ${YELLOW}${uid}${RESET}/${YELLOW}${primary_gid}${RESET}"

  if [[ "$VERBOSE" == "true" ]]; then
    echo "${BOLD}${WHITE}Home:${RESET} ${DIM}${home}${RESET}"
    echo "${BOLD}${WHITE}Shell:${RESET} ${DIM}${shell}${RESET}"
  fi

  echo "${CYAN}────────────────────────────────────────────────────────────────────${RESET}"

  # Display groups
  if [[ -z "$user_groups" ]]; then
    echo "${DIM}(no group memberships)${RESET}"
  else
    echo "${BOLD}${WHITE}Group Memberships:${RESET}"

    # Convert to array and sort
    IFS=' ' read -ra groups_array <<<"$user_groups"
    if [[ "$SORT_FIELD" == "id" ]]; then
      # Sort by group ID
      for group in "${groups_array[@]}"; do
        local gid=$(getent group "$group" | cut -d: -f3)
        echo "${group}:${gid}"
      done | sort -t: -k2 -n | while IFS=: read -r group gid; do
        print_group_info "$group" "$gid" "$primary_gid"
      done
    else
      # Sort by name (default)
      printf '%s\n' "${groups_array[@]}" | sort | while read -r group; do
        local gid=$(getent group "$group" | cut -d: -f3)
        print_group_info "$group" "$gid" "$primary_gid"
      done
    fi
  fi

  # Show permissions if requested
  if [[ "$SHOW_PERMISSIONS" == "true" ]] && [[ "$EUID" -eq 0 ]]; then
    echo ""
    echo "${BOLD}${WHITE}User-writable files in /etc owned by user's groups:${RESET}"
    find /etc -type f -group "$username" -perm -o=w 2>/dev/null |
      head -3 | while read -r file; do
      echo "  ${RED}⚠ ${file}${RESET}"
    done
  fi

  echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
}

# Helper function to print group info
print_group_info() {
  local group="$1"
  local gid="$2"
  local primary_gid="$3"

  if [[ "$SHOW_IDS" == "true" ]]; then
    if [[ "$gid" == "$primary_gid" ]]; then
      echo "  ${BOLD}${GREEN}• ${group}${RESET} ${DIM}(GID: ${YELLOW}${gid}${RESET}) ${BOLD}${BLUE}[Primary]${RESET}"
    else
      echo "  ${GREEN}• ${group}${RESET} ${DIM}(GID: ${YELLOW}${gid}${RESET})"
    fi
  else
    if [[ "$gid" == "$primary_gid" ]]; then
      echo "  ${BOLD}${GREEN}• ${group}${RESET} ${BOLD}${BLUE}[Primary]${RESET}"
    else
      echo "  ${GREEN}• ${group}${RESET}"
    fi
  fi

  # Show group members if detailed mode
  if [[ "$DETAILED" == "true" ]]; then
    local members=$(getent group "$group" | cut -d: -f4)
    if [[ -n "$members" ]]; then
      echo "    ${DIM}Members: ${members}${RESET}"
    fi
  fi
}

# Function to show all users and their groups
show_all_users() {
  echo "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}${WHITE}ALL USERS AND THEIR GROUPS${RESET}"
  echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"

  local count=0
  local users

  # Get sorted list of users
  if [[ "$SORT_FIELD" == "user" ]]; then
    users=$(getent passwd | cut -d: -f1 | sort)
  else
    users=$(getent passwd | cut -d: -f1)
  fi

  while read -r username; do
    # Skip system users if not verbose
    if [[ "$VERBOSE" != "true" ]]; then
      local uid=$(id -u "$username" 2>/dev/null)
      [[ "$uid" -lt 1000 ]] && [[ "$uid" -ne 0 ]] && continue
    fi

    echo "${CYAN}────────────────────────────────────────────────────────────────────${RESET}"

    # Get user info
    local user_info=$(getent passwd "$username")
    local uid=$(echo "$user_info" | cut -d: -f3)
    local gid=$(echo "$user_info" | cut -d: -f4)
    local user_groups=$(id -nG "$username" 2>/dev/null | tr ' ' ',')

    echo "${BOLD}${WHITE}User:${RESET} ${GREEN}${username}${RESET}"
    echo "${BOLD}${WHITE}UID/GID:${RESET} ${YELLOW}${uid}${RESET}/${YELLOW}${gid}${RESET}"
    echo "${BOLD}${WHITE}Groups:${RESET} ${DIM}${user_groups}${RESET}"

    if [[ "$SHOW_IDS" == "true" ]]; then
      echo "${BOLD}${WHITE}Group IDs:${RESET}"
      id -nG "$username" 2>/dev/null | tr ' ' '\n' | while read -r group; do
        local group_gid=$(getent group "$group" | cut -d: -f3 2>/dev/null)
        echo "  ${DIM}${group}:${group_gid}${RESET}"
      done
    fi

    ((count++))
  done <<<"$users"

  echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
  echo "${DIM}Total: ${count} users displayed${RESET}"
}

# Function to show current user's groups (default)
show_current_user() {
  local current_user
  current_user=$(whoami)
  get_user_groups "$current_user"
}

# Parse command line arguments
parse_args() {
  SHOW_IDS="false"
  DETAILED="false"
  COMPACT="false"
  TABLE_FORMAT="false"
  VERBOSE="false"
  SHOW_PERMISSIONS="false"
  SORT_FIELD="name"

  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      show_help
      ;;
    -a | --all)
      MODE="all_users"
      ;;
    -c | --compact)
      COMPACT="true"
      ;;
    -d | --details)
      DETAILED="true"
      ;;
    -g | --group)
      shift
      if [[ -z "$1" ]]; then
        echo "${RED}Error: Group name required for -g option${RESET}" >&2
        exit 1
      fi
      MODE="group_members"
      GROUP_NAME="$1"
      ;;
    -i | --id)
      SHOW_IDS="true"
      ;;
    -l | --list)
      MODE="list_groups"
      ;;
    -m | --my)
      MODE="current_user"
      ;;
    -n | --no-color)
      NO_COLOR=1
      # Re-evaluate color variables
      if [[ -n "$NO_COLOR" ]]; then
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        MAGENTA=""
        CYAN=""
        WHITE=""
        BOLD=""
        DIM=""
        RESET=""
        BG_BLUE=""
        BG_GRAY=""
      fi
      ;;
    -p | --permissions)
      SHOW_PERMISSIONS="true"
      ;;
    -s | --sort)
      shift
      case "$1" in
      name | id | user)
        SORT_FIELD="$1"
        ;;
      *)
        echo "${RED}Error: Invalid sort field. Use: name, id, user${RESET}" >&2
        exit 1
        ;;
      esac
      ;;
    -t | --table)
      TABLE_FORMAT="true"
      ;;
    -u | --user)
      shift
      if [[ -z "$1" ]]; then
        echo "${RED}Error: Username required for -u option${RESET}" >&2
        exit 1
      fi
      MODE="specific_user"
      SPECIFIC_USER="$1"
      ;;
    -v | --verbose)
      VERBOSE="true"
      ;;
    -*)
      echo "${RED}Error: Unknown option '$1'${RESET}" >&2
      echo "Use ${GREEN}lsgroups --help${RESET} for usage information"
      exit 1
      ;;
    *)
      # Assume it's a username
      MODE="specific_user"
      SPECIFIC_USER="$1"
      ;;
    esac
    shift
  done
}

# Main execution
main() {
  MODE="current_user" # Default mode

  # Parse arguments
  parse_args "$@"

  # Execute based on mode
  case "$MODE" in
  all_users)
    show_all_users
    ;;
  group_members)
    show_group_members "$GROUP_NAME"
    ;;
  list_groups)
    list_all_groups
    ;;
  specific_user)
    get_user_groups "$SPECIFIC_USER"
    ;;
  current_user)
    show_current_user
    ;;
  esac
}

# Run main function
main "$@"
