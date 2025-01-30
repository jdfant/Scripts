#! /bin/bash

PYTHON_VERSION="3.13" 
BUILD_DIR=~/VIRTUALENV
PREFIX="${BUILD_DIR}"/python
TARGET="${PREFIX}"/lib/${PYTHON_VERSION}/site-packages/
ZIP_FILE=pipe2_lambda_layer_"$(date '+%Y-%m-%d')".zip
ZIP_FILE_PATH=~/ZIP_FILES

GIT_SOURCE=~/GIT/lambdas

check_apps(){
    if hash python3 &> /dev/null ;then
        echo -n
    else
        echo -e "\\n python3 is not installed\\n\\n Install python3 and restart script.\\n"
        exit 1
    fi
    if hash pip3 &> /dev/null ;then
        echo -n
    else
        echo -e "\\n pip3 is not installed\\n\\n Install pip3 and restart script.\\n"
        exit 1
    fi
    if hash zip &> /dev/null ;then
        echo -n
    else
        echo -e "\\n zip is not installed\\n\\n Install zip and restart script.\\n"
        exit 1
    fi
}

virtualenv_build(){
    mkdir -p "${BUILD_DIR}"
    cp requirements.txt "${BUILD_DIR}"
    cd "${BUILD_DIR}" || exit
    python3 -m venv "$(pwd)"
    source bin/activate
    pip3 install --no-cache-dir -U "$(grep pip requirements.txt)" 2>/dev/null
    pip3 install --no-cache-dir -U "$(grep setup requirements.txt)" 2>/dev/null
    pip3 install --no-cache-dir -U wheel 2>/dev/null
    pip3 install --no-cache-dir -r requirements.txt --prefix "${PREFIX}"

    deactivate
}

copy_common(){
    cd "${GIT_SOURCE}" || exit
    git pull
    git checkout layers_rework
    echo -e "\\nWorking Branch Name is:\\n$(git branch)\\n\\n"
    cd "${BUILD_DIR}" || exit
    cp -Rv "${GIT_SOURCE}"/az/common "${TARGET}"
}

create_zip(){
    cd "${TARGET}" || exit
    rm -f "${BUILD_DIR}"/requirements.txt
    mkdir -p "${ZIP_FILE_PATH}"
    zip -r "${ZIP_FILE_PATH}"/"${ZIP_FILE}" ./* 
    echo
    zip -T "${ZIP_FILE_PATH}"/"${ZIP_FILE}"
    echo -e "\\nLambda Layer Zip file is ready in ${ZIP_FILE_PATH}/${ZIP_FILE}\\n"
}

check_apps
virtualenv_build
copy_common
create_zip
