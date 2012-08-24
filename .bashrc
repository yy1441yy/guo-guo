# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
alias dfsls='hadoop dfs -ls'
alias dfsrm='hadoop dfs -rm'       # rm
alias dfscat='hadoop dfs -cat'     # cat
alias dfsrmr='hadoop dfs -rmr'     # rm -r
alias dfsmkdir='hadoop dfs -mkdir' # mkdir
alias dfsput='hadoop dfs -put'     # HDFS
alias dfsget='hadoop dfs -get'     # HDFS
alias gitshow='git show | grep "+++ b/"'
alias editrc='vi ~/.bashrc'
alias rushrc='source ~/.bashrc'
alias grep='grep --color'
alias vim='vim -O'
alias vi='vim'
alias ci='vim'
alias lld='ll | grep ^d'
alias python='/home/bkapps/download/Python-2.7.3/python'
alias searh='history | grep $1'
alias runs='./script/devel/server -p 9899 -e'
alias runsql='mysql -h mysql.lo.mixi.jp -u root -P 3306'
alias runt='perl -Ilib -I/usr/local/bundle-plack/lib/perl5 -I/usr/local/bundle-plack/lib/perl5/x86_64-linux-thread-multi script/voice/twitter_crawler/worker.pl --max-workers=2 --time-to-live=600 & perl -Ilib -I/usr/local/bundle-plack/lib/perl5 script/voice/twitter_crawler/manager.pl --max-clients=2 --time-to-live=600 &'
alias vii='perl /home/bkapps/cmd/vii.pl $1'

# User specific aliases and functions
function get_git_current_branch {
    local dir=. head GIT_BRANCH
    until [ "$dir" -ef / ]; do
        if [ -f "$dir/.git/HEAD" ]; then
            head=$(< "$dir/.git/HEAD")
            if [[ $head = ref:\ refs/heads/* ]]; then
                GIT_BRANCH="${head#*/*/}"
            elif [[ $head != '' ]]; then
                GIT_BRANCH="detached"
            else
                GIT_BRANCH="unknow"
            fi
            echo $GIT_BRANCH
            return
        fi
        dir="../$dir"
    done
}

function _get_git_sub_command {
    git | head --lines -2 | tail --lines +8 | cut -c 4-11
}

function get_git_branchs {
    git branch | cut -c 3-
    git branch --remotes | cut -c 3- | sed -e '/^origin\//!d' -e '/^origin\/HEAD/d' -e 's/^origin\///'
    #local local_branchs=($(git branch | cut -c 3-))
    #local remote_branchs=($(git branch --remotes | cut -c 3- | sed -e '/^origin\//!d' -e '/^origin\/HEAD/d' -e 's/^origin\///'))
    #echo "${local_branchs[@]} ${remote_branchs[@]}"
}

function get_default_ps1 {
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

function prompt_command {
    local DEFAULT_PS1=$(get_default_ps1)
    local GIT_CURRENT_BRANCH=$(get_git_current_branch)

    if [ "y$GIT_CURRENT_BRANCH" != "y" ]; then
        local BRANCH_COLOR_FRONT="32" # green
        local BRANCH_COLOR_BACK="40" # black
        [ "y$(git diff)" == "y" ] || BRANCH_COLOR_FRONT="31" # red
        [ $GIT_CURRENT_BRANCH == "master" ] && BRANCH_COLOR_BACK="47" # white
        local BRANCH_COLOR="\[\033[0$BRANCH_COLOR_FRONT;0${BRANCH_COLOR_BACK}m\]"
        DEFAULT_PS1="$DEFAULT_PS1 → $BRANCH_COLOR($GIT_CURRENT_BRANCH)\[\033[0m\]"
    fi
    PS1="[$DEFAULT_PS1]$ "
}

PROMPT_COMMAND='prompt_command'

function gi {
    local CMDS GIT_CURRENT_BRANCH=$(get_git_current_branch)

    if [ "y$1" == "yclone" ]; then
        shift
        [ $# -ne 1 ] && echo "Argument not correct" && return
        CMDS=("git clone git@git.lo.mixi.jp:$@")
    elif [ "y$1 $2" == "yremote add" ]; then
        local reRepo=$3
        shift 3
        [ $# -ne 1 ] && echo "Argument not correct" && return
        CMDS=("git remote add $reRepo git@git.lo.mixi.jp:$@" "git fetch $reRepo")
    fi
    if [ "y$CMDS" == "y" ]; then
        echo "sorry, unknown arguments given, will run \`git $@\`"
        git $@
    else
        local y
        for((y=0; y<${#CMDS[@]}; y++)); do
            local CMD=${CMDS[$y]}
            echo "Executing \`$CMD\`"
            $CMD || break
        done
    fi
}

function _get_completed_branch {
    local branchs=($(get_git_branchs)) seleted_branchs=
    local branch=
    for branch in ${branchs[@]}; do
        [[ $branch == $1* ]] && seleted_branchs="$seleted_branchs $branch"
    done
    echo "$seleted_branchs"
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
                [ $COMP_CWORD -eq 1 ] && compreply="co "
                compreply="${compreply}$(_get_completed_branch ${COMP_WORDS[2]})"

            fi
            ;;
        * )
            [ $COMP_CWORD -eq 1 ] && compreply="${compreply}$(_get_git_sub_command)"
            ;;
    esac
    [ "y$compreply" == "y" ] || COMPREPLY=($compreply)
}

complete -F _git git

export JAVA_HOME=/usr/java/jdk1.6.0_24
export PATH=$JAVA_HOME/bin:/home/bkapps/git/guo-guo/lib:/home/bkapps/cmd/shell:/home/bkapps/google_appengine:$PATH
export HADOOP_HOME=/usr/lib/hadoop
export PIG_CLASSPATH=$HADOOP_HOME/conf
export SVN_EDITOR="vim -c \"1!svn info | grep '^URL:' | sed -e 's/.*svn:\/\/jupiter\/\(.*\)/[\1] /'\" -c 'norm $'"
