export PATH=.:~/dotfiles/bin:~/bin:/opt/local/bin:/opt/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/local/Library/Frameworks/Python.framework/Versions/2.7/bin:/opt/local/Library/Frameworks/Python.framework/Versions/3.2/bin:/Users/wpfnuer/Library/Python/2.7/bin
export LIBRARY_PATH=/opt/local/lib
export EDITOR='mvim -v -f'
export MAVEN_OPTS=-Xmx1024m
export MAPPING_SIGN_KEY=~/fe.der
alias vim="mvim -v"
alias vi='vim'
alias ssh="ssh -o ServerAliveInterval=60"

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it
shopt -s histreedit # reedit a history substitution line if it failed
shopt -s histverify # edit a recalled history line before executing

# Save and reload the history after each command finishes
. ~/dotfiles/powerline/powerline/bindings/bash/powerline.sh
export PROMPT_COMMAND="$PROMPT_COMMAND; history -a; history -c; history -r"


alias vim="mvim -v"
alias vi='vim'
alias ssh="ssh -o ServerAliveInterval=60"
alias jenkins="ssh jenkins@jenkins.devbliss.com"
alias jura="ssh root@d-v137.spreegle.de"
alias ls='ls -G'
alias ll='ls -la'

source ~/jura_ec2_vars

source /etc/bash_completion.d/fab
source /etc/bash_completion.d/git
source /opt/local/etc/bash_completion.d/git-devbliss

# Automatically add completion for all aliases to commands having completion functions
function alias_completion {
    local namespace="alias_completion"

    # parse function based completion definitions, where capture group 2 => function and 3 => trigger
    local compl_regex='complete( +[^ ]+)* -F ([^ ]+) ("[^"]+"|[^ ]+)'
    # parse alias definitions, where capture group 1 => trigger, 2 => command, 3 => command arguments
    local alias_regex="alias ([^=]+)='(\"[^\"]+\"|[^ ]+)(( +[^ ]+)*)'"

    # create array of function completion triggers, keeping multi-word triggers together
    eval "local completions=($(complete -p | sed -Ene "/$compl_regex/s//'\3'/p"))"
    (( ${#completions[@]} == 0 )) && return 0

    # create temporary file for wrapper functions and completions
    rm -f "/tmp/${namespace}-*.tmp" # preliminary cleanup
    local tmp_file="$(mktemp "/tmp/${namespace}-${RANDOM}.tmp")" || return 1

    # read in "<alias> '<aliased command>' '<command args>'" lines from defined aliases
    local line; while read line; do
        eval "local alias_tokens=($line)" 2>/dev/null || continue # some alias arg patterns cause an eval parse error 
        local alias_name="${alias_tokens[0]}" alias_cmd="${alias_tokens[1]}" alias_args="${alias_tokens[2]# }"

        # skip aliases to pipes, boolan control structures and other command lists
        # (leveraging that eval errs out if $alias_args contains unquoted shell metacharacters)
        eval "local alias_arg_words=($alias_args)" 2>/dev/null || continue

        # skip alias if there is no completion function triggered by the aliased command
        [[ " ${completions[*]} " =~ " $alias_cmd " ]] || continue
        local new_completion="$(complete -p "$alias_cmd")"

        # create a wrapper inserting the alias arguments if any
        if [[ -n $alias_args ]]; then
            local compl_func="${new_completion/#* -F /}"; compl_func="${compl_func%% *}"
            # avoid recursive call loops by ignoring our own functions
            if [[ "${compl_func#_$namespace::}" == $compl_func ]]; then
                local compl_wrapper="_${namespace}::${alias_name}"
                    echo "function $compl_wrapper {
                        (( COMP_CWORD += ${#alias_arg_words[@]} ))
                        COMP_WORDS=($alias_cmd $alias_args \${COMP_WORDS[@]:1})
                        $compl_func
                    }" >> "$tmp_file"
                    new_completion="${new_completion/ -F $compl_func / -F $compl_wrapper }"
            fi
        fi

        # replace completion trigger by alias
        new_completion="${new_completion% *} $alias_name"
        echo "$new_completion" >> "$tmp_file"
    done < <(alias -p | sed -Ene "s/$alias_regex/\1 '\2' '\3'/p")
    source "$tmp_file" && rm -f "$tmp_file"
}; alias_completion