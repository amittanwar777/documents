autoload -Uz vcs_info
precmd() { vcs_info }
PS1='%n@%m:%~${vcs_info_msg_0_}%# '
zstyle ':vcs_info:git:*' formats ' (%b)'