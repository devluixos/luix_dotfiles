# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/luix/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
#
# --- Git prompt via built-in vcs_info ---
autoload -Uz vcs_info
zstyle ':vcs_info:git*' enable git
zstyle ':vcs_info:git*+set-message:*' hooks git-st git-untracked git-aheadbehind
zstyle ':vcs_info:git*' get-revision true
zstyle ':vcs_info:git*' check-for-changes true
zstyle ':vcs_info:*' formats '(%b%u%c%a)'
zstyle ':vcs:info:*' actionformats '(%b|%a%u%c)'

# hooks to build status markers
function +vi-git-st() {
	local s=$(git status --porcelain 2>/dev/null)
	[[ -n "$s" ]] && hook_com[stages-changes]="*"
}
function +vi-git-untracked() {
	local q=$(git ls-files --others --exclude-standard 2>/dev/null)
	[[ -n "$s" ]] && hook_com[stages-changes]="?"
}
function +vi-git-aheadbehind() {
	local ab=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
	[[ -n "$ab" ]] || return
	local a=${ab%%    *} b=${ab##*    }
	[[ "$a" != 0 ]] && hook_com[ahead]="⇡"
	[[ "$b" != 0 ]] && hook_com[behind]="⇣"
}

precmd() { vcs_info }

# user@host cwd (git)
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %F{magenta}${vcs_info_msg_0_}%f %# '
