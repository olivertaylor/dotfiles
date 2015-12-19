# Enable what needs to be enabled
setopt prompt_subst
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git 
zstyle ':vcs_info:*' use-simple true
zstyle ':vcs_info:*' check-for-changes true
precmd () { vcs_info }

# This builds the vcs_info that goes in the prompt
zstyle ':vcs_info:*' formats ' %F{2}%b%u%c%f%F{3}%m%f'
# %b = branch
# %u = String from unstagedstr 
# %c = String from stagedstr 
# %m = misc (see below)

# actionformats are used when something is happening in
# the repo, like a merge or rebase.
# %a = action identifier
zstyle ':vcs_info:*' actionformats '(%a)'

# if there are staged/unstaged changes in the repository.
zstyle ':vcs_info:*' stagedstr '*'
zstyle ':vcs_info:*' unstagedstr '*'

# Next, setup what's in %m Misc

# This runs functions when vcs displays a message
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-aheadbehind

# This shows a marker if there are untracked files in the repo
function +vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
    git status --porcelain | grep '??' &> /dev/null ; then
    hook_com[unstaged]+=' %F{1}+%f'
  fi  
}

# This shows a marker if your repo is ahead/behind the remote
function +vi-git-aheadbehind() {
  local ahead behind
  local -a gitstatus

  ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | sed 's/ //g')
  (( $ahead )) && gitstatus+=( " ↑${ahead}" )

  behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | sed 's/ //g')
  (( $behind )) && gitstatus+=( " ↓${behind}" )

  hook_com[misc]+=${(j::)gitstatus}
}

# And finally the prompt...

PROMPT='
%F{12}%~%f%F{1}%(1j. (%j jobs).)%f${vcs_info_msg_0_}
%F{9}❯ %f'
