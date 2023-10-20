#!/bin/sh


function generateRoleDirTree()
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


function generatePlaybookDirTree()
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

 



#alias gen_ansible="mkdir"






