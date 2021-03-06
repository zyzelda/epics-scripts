#!/bin/bash
#
#
#

# Stuff to customize
SYNAPPS_DIR=synApps

setup() {

  GITHUB=https://github.com

  SYNAPPS_MODULES=
  EPICS_MODULES=
  AREADETECTOR_MODULES=

  ### 
  SYNAPPS_MODULES+=" configure"
  SYNAPPS_MODULES+=" utils"
  SYNAPPS_MODULES+=" documentation"
  ### 
  EPICS_MODULES+=" alive"
  EPICS_MODULES+=" asyn"
  EPICS_MODULES+=" autosave"
  EPICS_MODULES+=" busy"
  EPICS_MODULES+=" calc"
  EPICS_MODULES+=" camac"
  EPICS_MODULES+=" caputRecorder"
  EPICS_MODULES+=" dac128V"
  EPICS_MODULES+=" delaygen"
  EPICS_MODULES+=" dxp"
  EPICS_MODULES+=" iocStats"
  EPICS_MODULES+=" ip"
  EPICS_MODULES+=" ipac"
  EPICS_MODULES+=" ip330"
  EPICS_MODULES+=" ipUnidig"
  EPICS_MODULES+=" love"
  EPICS_MODULES+=" mca"
  EPICS_MODULES+=" measComp"
  EPICS_MODULES+=" modbus"
  EPICS_MODULES+=" motor"
  EPICS_MODULES+=" optics"
  EPICS_MODULES+=" quadEM"
  EPICS_MODULES+=" softGlue"
  EPICS_MODULES+=" sscan"
  EPICS_MODULES+=" std"
  # https://github.com/paulscherrerinstitute/StreamDevice.git
  EPICS_MODULES+=" stream"
  EPICS_MODULES+=" vac"
  EPICS_MODULES+=" vme"
  EPICS_MODULES+=" xxx"
  ###
  AREADETECTOR_MODULES+=" ADCore"
  AREADETECTOR_MODULES+=" ADSimDetector"
  AREADETECTOR_MODULES+=" ADSupport"

}

#
enterDirIfExists() {
  echo "> ${1}"
  if [ -d "${1}" ]
  then
    cd ${1}
  else
    echo "\"${1}\" directory doesn't exist"
    exit 1
  fi
}

#
exitDir() {
  if [[ "${1}" != "support" && "${1}" != "areaDetector" ]]
  then
    cd ..
  fi
}

#
status() {
  enterDirIfExists ${1}
  
  if [[ ${FULL_STATUS} == "False" ]]
  then
    #!git status | grep "Your branch"
    STATUS=`git status | grep "Your branch"`
    if [[ "${STATUS}" != "" ]]; then
      echo ${STATUS}
    else
      # Old versions of git lack this message, so simulate it
      echo "Your branch is up-to-date with 'origin/master'."
    fi  
  else
    git status
  fi
  
  exitDir ${1}
}

#
fetch() {
  enterDirIfExists ${1}
  
  git fetch
  
  exitDir ${1}
}

# rebase is a windows program, so function had to have a different name
update() {
  enterDirIfExists ${1}
  
  STATUS=`git status | grep "Your branch"`
  if [[ "${STATUS}" != "" ]]; then
    echo ${STATUS}
  else
    # Old versions of git lack this message, so simulate it
    echo "Your branch is up-to-date with 'origin/master'."
  fi
  
  if [[ "${STATUS}" =~ "can be fast-forwarded" ]]
  then
    # Auto stashing and applying changes frequently causes merge conflicts
    #!echo "- Rebasing ${1}"
    #!git stash
    #!git rebase origin/master
    #!git stash apply
    
    if [[ ${MANUAL_REBASE} == "True" ]]
    then
      ### Manually rebase instead
      echo "- Rebasing ${1} manually. Type \"exit\" when done."
      echo "$ git status"
      git status
      
      # Change the prompt so the user knows they're in a different shell
      if [[ "${OS}" == "Windows_NT" ]]
      then
        OLD_MSYSTEM=${MSYSTEM}
        export MSYSTEM="Rebasing ${1}"
        
        # Run a new bash instance for interactive rebasing
        bash
        
        # Restore the original prompt
        export MSYSTEM=${OLD_MSYSTEM}
      else
        # Run a new bash instance for interactive rebasing
        # Note --rcfile also works
        bash --init-file <(echo "PS1='Rebasing ${1} $ '") -i
      fi
    else
      ### Automatically rebase
      echo "- Automatically rebasing ${1}"
      git stash && git rebase origin/master && git stash apply
      echo "$ git status"
      git status
    fi
  fi
  
  exitDir ${1}
}

# The main routine of the script
main() {
  # Create module lists
  setup
  
  # It is assumed that this dir already exists
  cd ${SYNAPPS_DIR}
  
  ### support
  ${FUNC} support

  ### synApps modules
  for module in ${SYNAPPS_MODULES}; do
    ${FUNC} ${module}
  done

  ### EPICS modules
  for module in ${EPICS_MODULES}; do
    ${FUNC} ${module}
  done

  ### areaDetector
  ${FUNC} areaDetector

  ### areaDetector modules
  for module in ${AREADETECTOR_MODULES}; do
    ${FUNC} ${module}
  done
  
  cd ..
}

# The cloning function is very similar to main(), but not similar enough to be combined
clone() {
  # Create module lists
  setup
  
  # It is assumed that this dir already exists
  cd ${SYNAPPS_DIR}
  
  ### support
  if [ -d "support" ]; then
    echo "support already exists"
  else
    echo "cloning support"
    git clone --quiet ${GITHUB}/EPICS-synApps/support.git
  fi
  cd support
  
  ### synApps modules
  for module in ${SYNAPPS_MODULES}; do
    if [ -d "${module}" ]; then
      echo "${module} already exists"
    else
      echo "cloning ${module}"
      git clone --quiet ${GITHUB}/EPICS-synApps/${module}.git
    fi
  done
  
  ### EPICS modules
  for module in ${EPICS_MODULES}; do
    if [ -d "${module}" ]; then
      echo "${module} already exists"
    else
      echo "cloning ${module}"
      git clone --quiet ${GITHUB}/epics-modules/${module}.git
      
      # Handle special cases
      if [ "${module}" == "stream" ]; then
        # stream is just a wrapper; update the submodule
        cd stream
        echo "initializing StreamDevice submodule"
        git submodule --quiet init
        # the --quiet flag appears to be ignored when doing the update with git v1.7.1
        git submodule --quiet update
        cd ..
      fi
      
    fi
  done
  
  ### areaDetector
  if [ -d "areaDetector" ]; then
    echo "areaDetector already exists"
  else
    echo "cloning areaDetector"
    git clone --quiet ${GITHUB}/areaDetector/areaDetector
  fi
  cd areaDetector

  ### areaDetector modules
  for module in ${AREADETECTOR_MODULES}; do
    if [ -d "${module}" ]; then
      #!echo "${module} already exists"
      if [ "$(ls -A ${module})" ]; then
        echo "${module} is not empty"
      else
        echo "cloning ${module}"
        git clone --quiet ${GITHUB}/areaDetector/${module}.git
      fi
    else
      echo "cloning ${module}"
      git clone --quiet ${GITHUB}/areaDetector/${module}.git
    fi
  done
  
  cd ..
  
  if [[ "${WGET_NOT_FOUND}" == "0" ]]
  then
    mkdir tar

    if [ -d "allenBradley-2-3" ]; then
      echo "allenBradley-2-3 already exists"
    else
      echo "fetching & extracting allenBradley-2-3"
      # http://www.aps.anl.gov/epics/modules/bus/allenBradley
      ${WGET} --no-check-certificate --quiet -O tar/allenBradley-2.3.tar.gz https://www.aps.anl.gov/epics/download/modules/allenBradley-2.3.tar.gz 
      
      # The synApps build can't handle "."
      #!tar xzvf tar/allenBradley-2.3.tar.gz
      tar xzf tar/allenBradley-2.3.tar.gz
      mv allenBradley-2.3 allenBradley-2-3
    fi
    
    if [ -d "seq-2-2-4" ]; then
      echo "seq-2-2-4 already exists"
    else
      echo "fetching & extracting seq-2-2-4"
      # http://www-csr.bessy.de/control/SoftDist/sequencer/Installation.html#download
      ${WGET} --no-check-certificate --quiet -O tar/seq-2.2.4.tar.gz http://www-csr.bessy.de/control/SoftDist/sequencer/releases/seq-2.2.4.tar.gz
      
      # The synApps build can't handle "."
      #!tar xzvf tar/seq-2.2.4.tar.gz
      tar xzf tar/seq-2.2.4.tar.gz
      mv seq-2.2.4 seq-2-2-4
    fi
    
    rm -rf tar/
  fi

  echo "done cloning synApps"
}

#!echo ${#}
# Parse command-line arg
if [[ ${#} -eq 1 ]]
then
  OPT=${1}
  
  case ${OPT} in 
    "clone")
      echo "-> clone"
      WGET=`which wget`
      WGET_NOT_FOUND=$?
      
      if [[ ${WGET_NOT_FOUND} == "1" ]]
      then
        echo ""
        echo "Error: wget not found. wget is required for cloning"
      else
        echo "Found wget: ${WGET}"
      fi
      ;;
    
    "fetch")
      echo "-> fetch"
      FUNC=fetch
      ;;
    
    "stat")
      echo "-> status"
      FULL_STATUS=False
      FUNC=status
      ;;
    
    "status")
      echo "-> status-full"
      FULL_STATUS=True
      FUNC=status
      ;;
    
    "rebase")
      echo "-> rebase"
      MANUAL_REBASE=True
      FUNC=update
      ;;
    
    "auto-rebase")
      echo "-> auto-rebase"
      MANUAL_REBASE=False
      FUNC=update
      ;;
    
    *)
      echo "Error: ${OPT} is not a valid option"
      exit 1
      ;;
  esac
  
  if [ ! -d "${SYNAPPS_DIR}" ]
  then
    SYNAPPS_DIR_EXISTS=False
    if [[ "${OPT}" == "clone" ]]
    then
      mkdir ${SYNAPPS_DIR}
    else
      echo "Error: ${SYNAPPS_DIR} doesn't exist. Have you done a clone yet?"
      exit 1
    fi
  fi
  
else
  echo "Usage: synApps.sh <clone|fetch|status|stat|rebase|auto-rebase>"
  exit 1
fi

# Do whatever was requested
if [[ "${OPT}" == "clone" ]]
then
  clone
else
  main
fi
