# Add the following to your .bashrc file:

PS1="\u@\h:\w \$(parse_git_branch)\$ "

parse_git_branch() {
  git branch 2> /dev/null | grep -v "^*" | awk '{print "(" "$NF" ")"}'
}

# Source the changes:
source ~/.bashrc
