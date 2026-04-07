#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(dircolors ~/.dircolors)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\[\e[38;5;221m\]\h\[\e[0m\] \[\e[38;5;189m\]\w\[\e[0m\] \[\e[38;5;221m\]❯\[\e[0m\] '
