#!/bin/bash

export RC_SESSION_NAME="rdubya_1986"
export MAIN_WINDOW_NAME="login-01.czbiohub.org"
export SECONDARY_WINDOW_NAME="login-02.czbiohub.org"
export RC_DEF_SHELL="bash"

export CODE=${HOME}/Documents/code



function pull_all_gitolite_repos()
{

	pkill -5 ssh-agent
	eval `ssh-agent`
	ssh-add

    ssh -A -i ~/.ssh/id_ecdsa -t -l randall.white login-02.czbiohub.org ssh -T -A gitolite3@frankie.czbiohub.org info | grep " R W" 2> /dev/null | sed 's/ R W*//g' | xargs -I'{}' git clone gitolite3@frankie.czbiohub.org:'{}'

}


function gen_ansible_role_dir_tree()
{
    local roleName=$1 
    
    if ! [ -n ${roleName} ]
    then 
        echo "I need a directory name"

        return 1

    fi

    if ! [ -e ./roles ]
    then 
        mkdir -p ./roles
    fi 
 
    dirArray=( "templates" "tasks" "defaults" "handlers" "tests" "files" "vars" "meta" )

    pushd ./roles 
    
    for dirName in ${dirArray[@]}; do
    
    mkdir -p ${roleName}/${dirName}
    touch ${roleName}/${dirName}/.gitkeep

    done

    
    
    echo "# ansible role: ${roleName}" >  ${roleName}/README.md
    echo "" >> ${roleName}/README.md

    
    popd 

    
    return 0 
}


function gen_ansible_playbook_dir_tree()
{
    local playbookName=$1 
    
    if ! [ -n ${playbookName} ]
    then 
        echo "I need a directory name"

        return 1

    fi

    if ! [ -e ${playbookName} ]
    then 
        mkdir -p ${playbookName}
    fi 

    dirArray=( "group_vars" "host_vars" "library" "module_utils" "filter_plugins" "tasks" )

    
    
    for dirName in ${dirArray[@]}; do
    
    mkdir -p ${playbookName}/${dirName}
    touch ${playbookName}/${dirName}/.gitkeep

    done
    
    echo "# ansible playbook: ${playbookName}" >  ${playbookName}/README.md
    echo "" >> ${playbookName}/README.md
        
    echo "# main playbook: ${playbookName}" > ${playbookName}/site.yml
    echo "---" >> ${playbookName}/site.yml
    
    echo "---" > ${playbookName}/production

    echo "---" > ${playbookName}/staging
    

    return 0 
}

 
function command_shell_init()
{

case $1 in
    "sdiag")
       ${RC_DEF_SHELL} -c "sdiag | less" 
    ;;
    "sleep")
       ${RC_DEF_SHELL} -c "sleep 3"
    ;;
    "exercise")
        echo "Time for gym"
    ;;
    *)
        echo "Do nothing"
    ;;
esac

}


function gen_tmux_session_for_servers()
{

SESSION_RETURN_STRING=$(tmux list-sessions | cut -d ':' -f 1 | grep rdubya_1986)

if [ "${SESSION_RETURN_STRING}" = "${RC_SESSION_NAME}" ]
then 
#attach to the session
tmux attach -t ${RC_SESSION_NAME}
else
#lets start the tmux server first 
tmux start-server

# creat windows for session
tmux new-session -d -s ${RC_SESSION_NAME} -n main_window -d "${RC_DEF_SHELL} -l -c \"sdiag |less\"; /usr/bin/env ${RC_DEF_SHELL} -i"
tmux new-window "${RC_DEF_SHELL} -l -c \"ssh login-02\""

tmux attach -t ${RC_SESSION_NAME}

fi 

}



function start_ssh_agent()
{
    #just some simple crap
    pkill -5 ssh-agent 

    eval `ssh-agent`

    ssh-add 


}

#exporting shell functions
export -f start_ssh_agent
export -f command_shell_init
export -f gen_tmux_session_for_servers
export -f gen_ansible_playbook_dir_tree
export -f gen_ansible_role_dir_tree
export -f pull_all_gitolite_repos








