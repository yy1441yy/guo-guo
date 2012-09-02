# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export JAVA_HOME=/usr/java/jdk1.6.0_24
export PATH=$JAVA_HOME/bin:/home/bkapps/git/guo-guo/lib:/home/bkapps/script/shell:/home/bkapps/google_appengine:$PATH

# User specific aliases and functions
# aliases
alias editrc='vi ~/.bashrc'
alias rushrc='source ~/.bashrc'

alias grep='grep --color'
alias vi='vim'

[[ "$(python --version 2>&1 | cut -c 8-)" < "2.6" ]] && alias python='/home/bkapps/download/Python-2.7.3/python'

alias runs='./script/devel/server -p 9899 -e; echo'
alias runsd='./script/devel/server -p 9899 -e --debug; echo'
alias runsql='mysql -h mysql.lo.mixi.jp -u root -P 3306'
alias runt='perl -Ilib -I/usr/local/bundle-plack/lib/perl5 -I/usr/local/bundle-plack/lib/perl5/x86_64-linux-thread-multi script/voice/twitter_crawler/worker.pl --max-workers=2 --time-to-live=600 & perl -Ilib -I/usr/local/bundle-plack/lib/perl5 script/voice/twitter_crawler/manager.pl --max-clients=2 --time-to-live=600 &'

alias pvi='perl /home/bkapps/script/perl/vi.pl $1'

# functions
function _mgrep {
    grep "$1" * -R | grep -v /ssl/ | grep -v .production.js | grep "$1"
}

function _get_git_current_branch {
    local dir="." head= GIT_BRANCH=
    until [ "$dir" -ef / ]; do
        if [ -f "$dir/.git/HEAD" ]; then
            head=$(< "$dir/.git/HEAD")
            if [[ "$head" == "ref: refs/heads/"* ]]; then
                GIT_BRANCH="${head#*/*/}"
            elif [[ $head != "" ]]; then
                GIT_BRANCH="detached"
            else
                GIT_BRANCH="unknown"
            fi
            echo $GIT_BRANCH
            return
        fi
        dir="../$dir"
    done
}

function _get_git_sub_commands {
    local helpCommands=$(git | head --lines -2 | tail --lines +8 | cut -c 4-11)
    echo "$helpCommands"
    echo "cherry-pick"
}

function _get_git_branchs {
    git branch | cut -c 3-
    git branch -r | cut -c 3- | sed -e '/^origin\//!d' -e '/^origin\/HEAD/d' -e 's/^origin\///'
}

function _get_default_ps1 {
    #\u -> `whoami`
    #\h -> `hostname`
    #\w -> `pwd`
    #PS1="\u@\h \w"
    #\d date Wed Aug 22
    #\t time 15:48:17
    local w=`pwd | sed -e 's/\([^/]\)[^/]*\//\1\//g' -e 's/\/h\/\(b\|bkapps\)/~/'`
    local t="\[\033[033;040m\]\t\[\033[0m\]" # yellow, black
    echo "$w $t"
}

function _prompt_command {
    local DEFAULT_PS1=$(_get_default_ps1)
    local GIT_CURRENT_BRANCH=$(_get_git_current_branch)

    if [ -n "$GIT_CURRENT_BRANCH" ]; then
        local BRANCH_COLOR_FRONT="32" # green
        local BRANCH_COLOR_BACK="40" # black
        [ -z "$(git diff)" ] || BRANCH_COLOR_FRONT="31" # red
        [ $GIT_CURRENT_BRANCH == "master" ] && BRANCH_COLOR_BACK="47" # white
        local BRANCH_COLOR="\[\033[0$BRANCH_COLOR_FRONT;0${BRANCH_COLOR_BACK}m\]"
        DEFAULT_PS1="$DEFAULT_PS1 → $BRANCH_COLOR($GIT_CURRENT_BRANCH)\[\033[0m\]"
    fi
    PS1="[$DEFAULT_PS1]$ "
}

PROMPT_COMMAND='_prompt_command'

function gg {
    local CMDS= GIT_CURRENT_BRANCH=$(get_git_current_branch)

    if [[ "$1" == "pu"* ]]; then
        CMDS=("git $1 origin $GIT_CURRENT_BRANCH")
    elif [ "$1" == "clone" ]; then
        shift
        [ $# -ne 1 ] && echo "Argument not correct" && return
        CMDS=("git clone git@git.lo.mixi.jp:$@")
    elif [ "$1 $2" == "remote add" ]; then
        local reRepo=$3
        shift 3
        [ $# -ne 1 ] && echo "Argument not correct" && return
        CMDS=("git remote add $reRepo git@git.lo.mixi.jp:$@" "git fetch $reRepo")
    fi

    if [ -z "$CMDS" ]; then
        echo "sorry, unknown arguments given, will run \`git $@\`"
        git $@
    else
        local y=
        # for cmd in ${CMDS[@]}; do
        #  incorrect, $CMDS will be splitted two times
        for((y=0; y<${#CMDS[@]}; y++)); do
            local CMD=${CMDS[$y]}
            echo "Executing \`$CMD\`"
            $CMD || break
        done
    fi
}

function _filter {
    [ $# -lt "2" ] && return
    local startswith="$1"
    shift
    local list=("$@") selected_list=
    for element in ${list[@]}; do
        [[ $element == $startswith* ]] && selected_list="$selected_list $element"
    done
    echo $selected_list
}

function _get_completed_branchs {
    local branchs=$(_get_git_branchs)
    [ -z "$1" ] && echo $branchs && return
    echo $(_filter $1 $branchs)
}

function _get_completed_sub_commands {
    local commands=$(_get_git_sub_commands)
    [ -z "$1" ] && echo $commands && return
    echo $(_filter $1 $commands)
}

function _git {
    #echo "[$@]" #arguments -> [command, last element, penultimate element]
    #echo "[${COMP_WORDS[@]}]" #all elements
    #echo "[$COMP_CWORD]" #last index
    #echo "[${COMP_WORDS[$COMP_CWORD]}]" #last element
    #COMPREPLY=xxx #[command y] -> [command xxx], [command y ] -> [command y xxx]

    local sub_command=${COMP_WORDS[1]} last_input=$1
    local compreply=
    case "$sub_command" in
        "co" | "checkout" )
            if [ $COMP_CWORD -lt 3 ]; then
                [ $COMP_CWORD -eq 1 ] && compreply="co"
                compreply="$compreply $(_get_completed_branchs ${COMP_WORDS[2]})"
            fi
            ;;
        * )
            [ $COMP_CWORD -eq 1 ] && compreply=$(_get_completed_sub_commands ${COMP_WORDS[1]})
            ;;
    esac
    [ -z "$compreply" ] || COMPREPLY=($compreply)
}

complete -F _git git
