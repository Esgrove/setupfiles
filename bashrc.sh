#!/bin/bash
# Windows Bash profile

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Add alias for python3 since Windows defaults to just 'python'
alias python3=python

# Run ssh-agent automatically when you open bash.
# https://docs.github.com/en/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases?platform=windows
env=~/.ssh/agent.env

agent_load_env() {
    test -f "$env" && . "$env" >|/dev/null
}

agent_start() {
    (
        umask 077
        ssh-agent >|"$env"
    )
    . "$env" >|/dev/null
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2=agent not running
agent_run_state=$(
    ssh-add -l >|/dev/null 2>&1
    echo $?
)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add
fi

unset env
