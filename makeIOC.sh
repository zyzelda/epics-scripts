#!/bin/bash

num_args=$#

#!echo $0
#!echo $num_args
INDENT="> "

case $num_args in 
  2 )
    #!echo "$1"
    #!echo "$2"
    OS=$1
    PREFIX=$2
    
    # Validate OS choice
    if [ "${OS}" != "Linux" ] && [ "${OS}" != "vxWorks" ]
    then
      echo "\"${OS}\" is not a valid OS choice. Choose Linux or vxWorks."
      exit 1
    fi
    
    # Check for existing IOC dir
    if [ -d "${PREFIX}" ]
    then
      echo "The \"${PREFIX}\" directory already exists."
      exit 1
    fi 
    
    ;;
  
  * )
    echo "Usage: makeIOC.sh <vxWorks|Linux> <ioc_name>"
    exit 1
    ;;
esac

echo "${INDENT}Cloning https://github.com/kmpeters/xxx.git..."
git clone https://github.com/kmpeters/xxx.git

cd xxx

#!git branch

echo "${INDENT}Creating local ${OS} branch..."
git branch -f ${OS} origin/${OS}

#!git status
#!git branch

echo "${INDENT}Switching to ${OS} branch..."
git checkout ${OS}

echo "${INDENT}Creating local deployed branch..."
git branch deployed

echo "${INDENT}Switching to deployed branch..."
git checkout deployed

echo "${INDENT}Changing IOC prefix..."
./changePrefix.pl xxx ${PREFIX}
# Rename IOC startup directory
mv iocBoot/ioc${OS} iocBoot/ioc${PREFIX}
# Add renamed directories/files to git
git add iocBoot/ioc${PREFIX}
git add *${PREFIX}*
# Remove the changePrefix script
git rm changePrefix.pl

echo "${INDENT}Commiting changes to deployed branch..."
git commit -am "Initial commit of ${PREFIX} after running changePrefix.pl"

cd ..

echo "${INDENT}Renaming top-level directory..."
mv xxx ${PREFIX}

echo "${INDENT}${OS} IOC ${PREFIX} created successfully"
