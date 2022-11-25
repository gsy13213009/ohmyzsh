# Git version checking
autoload -Uz is-at-least
git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

#
# Functions
#

# The name of the current branch
# Back-compatibility wrapper for when this function was defined here in
# the plugin, before being pulled in to core lib/git.zsh as git_current_branch()
# to fix the core -> git plugin dependency.
function current_branch() {
  git_current_branch
}

# Pretty log messages
function _git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1
  fi
}
compdef _git _git_log_prettily=git-log

# Warn if the current branch is a WIP
function work_in_progress() {
  command git -c log.showSignature=false log -n 1 2>/dev/null | grep -q -- "--wip--" && echo "WIP!!"
}

# Check if main exists and use instead of master
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}

# Check for develop and similarly named branches
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo develop
}

#
# Aliases
# (sorted alphabetically)
#

alias g='git'

alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'
alias gap='git apply'
alias gapt='git apply --3way'

alias gb='git branch'
alias gba='git branch -a'
alias gbda='git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch -d 2>/dev/null'
alias gbD='git branch -D'
alias gbd='git branch -D'
alias gbl='git blame -b -w'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcn='git commit -v --no-edit'
alias gcn!='git commit -v --no-edit --amend'
alias gca='git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gcan!='git commit -v -a --no-edit --amend'
alias gcans!='git commit -v -a -s --no-edit --amend'
alias gcam='git commit -a -m'
alias gcsm='git commit -s -m'
alias gcas='git commit -a -s'
alias gcasm='git commit -a -s -m'
alias gcb='git checkout -b'
alias gcf='git config --list'

function gccd() {
  command git clone --recurse-submodules "$@"
  [[ -d "$_" ]] && cd "$_" || cd "${${_:t}%.git}"
}
compdef _git gccd=git-clone

alias gcl='git clone --recurse-submodules'
alias gclean='git clean -id'
alias gpristine='git reset --hard && git clean -dffx'
alias gcd='git checkout $(git_develop_branch)'
alias gcm='git commit -m'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcs='git commit -S'
alias gcss='git commit -S -s'
alias gcssm='git commit -S -s -m'

alias gd='git diff'
alias gdd='git diff --cached'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias gds='git diff --staged'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdup='git diff @{upstream}'
alias gdw='git diff --word-diff'

function gdnolock() {
  git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
compdef _git gdnolock=git-diff

function gdv() { git diff -w "$@" | view - }
compdef _git gdv=git-diff

alias gf='git fetch'
# --jobs=<n> was added in git 2.8
is-at-least 2.8 "$git_version" \
  && alias gfa='git fetch --all --prune --jobs=10' \
  || alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'

alias gfg='git ls-files | grep'

alias gg='git gui citool'
alias gga='git gui citool --amend'

function ggf() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git push --force origin "${b:=$1}"
}
compdef _git ggf=git-checkout
function ggfl() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git push --force-with-lease origin "${b:=$1}"
}
compdef _git ggfl=git-checkout

function ggl() {
  if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]; then
    git pull origin "${*}"
  else
    [[ "$#" == 0 ]] && local b="$(git_current_branch)"
    git pull origin "${b:=$1}"
  fi
}
compdef _git ggl=git-checkout

ggp() {
    local name=$1
    local force=$2
    [[ "$name" == "-f" ]] && name=$2 && force=$1
    [[ "$#" == 1 || "$#" == 2 ]] && local target="`git_current_branch`:`echo $name | sed s#^origin/##g`"
    echo "git push origin ${target:=`git_current_branch`} $force"
    git push origin "${target:=`git_current_branch`}" $force
    echo https://git.zhixiaoyoufang.com/ts/ts_mini_flutter/compare/master...ts:$name
}
ggcp() {
  local branch=$1
  local commit=$2
  [[ ! "$branch" =~ "/" ]] && branch=$2 && commit=$1
  local stat=`git status -s`
  if [[ -n "$stat" ]];then
    echo 'You have some changes'
    return
  fi
  gco -b "commit_temp_branch"
  git reset --hard origin/master
  gcp $commit
  ggp $branch '-f'
  gco -
  gbd "commit_temp_branch"
}
ggr() {
  local name=$1
  local push=$2
  if [[ "$2" == "-p" ]] || [[ "$2" == "-f" ]];then
    [[ "$2" == "-p" ]] && ggp $1
    [[ "$2" == "-f" ]] && ggp $1 -f
    return
  fi
  [[ -z "$1" ]] && git reset --hard origin/`git_current_branch` && return
  local target=`echo "$name" | sed s#^origin/##g`
  target="origin/$target"
  git reset --hard $target
}
ggb() {
  git reset --hard $1
}
alias ggd='(){[[ "$#" == 1 ]] && git push origin :`echo $1 | sed s#^origin/##g`}'
#alias ggr='(){git reset --hard ${1:=origin/`git_current_branch`}}'

compdef _git ggp=git-checkout
compdef _git ggd=git-checkout
compdef _git ggr=git-checkout
compdef _git ggb=git-checkout

# Problem: ggp zsh:12: command not found: __git-checkout_main
#
# The problem here is that the official Git completion was not prepared for 'complete_aliases
# This way you can manually define the completion with:
# compdef _git gco=git_checkout
# However, if you want to use zsh's format: gco=git-checkout and for it to work in the currently distributed version of Git, you can do this:
# alias __git-checkout_main=_git_checkout
# https://github.com/ohmyzsh/ohmyzsh/issues/2394
alias __git-checkout_main=_git_checkout

function ggpnp() {
  if [[ "$#" == 0 ]]; then
    ggl && ggp
  else
    ggl "${*}" && ggp "${*}"
  fi
}
compdef _git ggpnp=git-checkout

function ggu() {
  [[ "$#" != 1 ]] && local b="$(git_current_branch)"
  git pull --rebase origin "${b:=$1}"
}
compdef _git ggu=git-checkout

alias ggpur='ggu'
alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpush='git push origin "$(git_current_branch)"'

alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gpsup='git push --set-upstream origin $(git_current_branch)'

alias ghh='git help'

alias git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias gignore='git update-index --skip-worktree'
alias gignored='git ls-files -t | grep "^S"'
alias gunignore='git update-index --no-skip-worktree'
_gignoreall() {
  local no_staged=`git diff --name-only --relative`
  echo "ignored: $no_staged"
  gignore `echo $no_staged`
}
_gunignoreall() {
  local ignored=`gignored | sed 's/^S //g' | xargs`
  echo "unignore: $ignored"
  gunignore `echo $ignored`
}
alias gallignore='_gignoreall'
alias gallunignore='_gunignoreall'

alias gk='\gitk --all --branches &!'
alias gke='\gitk --all $(git log -g --pretty=%h) &!'

alias gl='git pull'
alias glg='git log --stat'
alias glgp='git log --stat -p'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"
alias glols="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat"
alias glod="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'"
alias glods="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short"
alias gloga="git log --graph --pretty=format:'%C(yellow)%h%Creset %C(bold blue)<%an>%Creset %C(yellow)%d%Creset %s %Cgreen(%ci)'"
alias glogn="git log --pretty=format:'%C(yellow)%h%Creset %C(bold blue)<%an>%Creset %C(yellow)%d%Creset %s %Cgreen(%ci)'"
alias glog="git log --graph --pretty=format:'%C(yellow)%h%Creset %C(bold blue)<%an>%Creset %C(yellow)%d%Creset %s %Cgreen(%ci)' --no-merges"
alias glp="_git_log_prettily"

alias gm='git merge'
alias gmom='git merge origin/$(git_main_branch)'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias gmum='git merge upstream/$(git_main_branch)'
alias gma='git merge --abort'

alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease'
alias gpf!='git push --force'
alias gpt='git push origin --tags'
alias gpoat='git push origin --all && git push origin --tags'
alias gpr='git pull --rebase'
alias gpu='git push upstream'
alias gpv='git push -v'

alias gr='git reset'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase -i'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grev='git revert'
alias grhh='git reset --hard'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grm='git rm'
alias grmc='git rm --cached'
alias grh='git reset --hard'
alias grH='git reset HEAD^'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grs='git restore'
alias grset='git remote set-url'
alias grss='git restore --source'
alias grst='git restore --staged'
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias gru='git reset --'
alias grup='git remote update'
alias grv='git remote -v'

alias gsb='git status -sb'
alias gsd='git svn dcommit'
alias gsh='git show'
alias gsi='git submodule init'
alias gsps='git show --pretty=short --show-signature'
alias gsr='git svn rebase'
alias gss='git status -s'
alias gst='git status'

# use the default stash push on git 2.13 and newer
is-at-least 2.13 "$git_version" \
  && alias gsta='git stash push' \
  || alias gsta='git stash save'

alias gs='git status ${1:=.}'
alias gsta='git stash save'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gstu='gsta --include-untracked'
alias gstall='git stash --all'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch -c'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'

alias gts='git tag -s'
alias gtv='git tag | sort -V'
alias gtl='gtl(){ git tag --sort=-v:refname -n -l "${1}*" }; noglob gtl'

alias gunwip='git log -n 1 | grep -q -c "\--wip--" && git reset HEAD~1'
alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gup='git pull --rebase'
alias gupv='git pull --rebase -v'
alias gupa='git pull --rebase --autostash'
alias gupav='git pull --rebase --autostash -v'
alias gupom='git pull --rebase origin $(git_main_branch)'
alias gupomi='git pull --rebase=interactive origin $(git_main_branch)'
alias glum='git pull upstream $(git_main_branch)'
alias gluc='git pull upstream $(git_current_branch)'

alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'

alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

alias gam='git am'
alias gamc='git am --continue'
alias gams='git am --skip'
alias gama='git am --abort'
alias gamscp='git am --show-current-patch'

function grename() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 old_branch new_branch"
    return 1
  fi

  # Rename branch locally
  git branch -m "$1" "$2"
  # Rename branch in origin remote
  if git push origin :"$1"; then
    git push --set-upstream origin "$2"
  fi
}

unset git_version
# Problem: ggp zsh:12: command not found: __git-checkout_main
#
# The problem here is that the official Git completion was not prepared for 'complete_aliases
# This way you can manually define the completion with:
# compdef _git gco=git_checkout
# However, if you want to use zsh's format: gco=git-checkout and for it to work in the currently distributed version of Git, you can do this:
# alias __git-checkout_main=_git_checkout
# https://github.com/ohmyzsh/ohmyzsh/issues/2394
alias __git-checkout_main=_git_checkout
