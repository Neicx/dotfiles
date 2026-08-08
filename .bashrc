#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(dircolors ~/.dircolors)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\[\e[38;5;221m\]\h\[\e[0m\] \[\e[38;5;189m\]\w\[\e[0m\] \[\e[38;5;221m\]❯\[\e[0m\] '

# opencode
export PATH=$HOME/.opencode/bin:$PATH
export PATH="$HOME/flutter/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

unzipd() {
  local nombre="${1%.zip}"
  mkdir -p "$nombre" && unzip "$1" -d "$nombre"
}
