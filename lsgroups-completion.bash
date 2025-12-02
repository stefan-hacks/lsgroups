#!/usr/bin/env bash
# lsgroups-completion.bash

_lsgroups_completion() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  opts="-h --help -a --all -c --compact -d --details -g --group -i --id -l --list -m --my -n --no-color -p --permissions -s --sort -t --table -u --user -v --verbose"

  case "${prev}" in
  -g | --group)
    # Complete group names
    local groups=$(getent group | cut -d: -f1)
    COMPREPLY=($(compgen -W "${groups}" -- ${cur}))
    return 0
    ;;
  -u | --user)
    # Complete usernames
    local users=$(getent passwd | cut -d: -f1)
    COMPREPLY=($(compgen -W "${users}" -- ${cur}))
    return 0
    ;;
  -s | --sort)
    # Complete sort fields
    COMPREPLY=($(compgen -W "name id user" -- ${cur}))
    return 0
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
  return 0
}

complete -F _lsgroups_completion lsgroups
