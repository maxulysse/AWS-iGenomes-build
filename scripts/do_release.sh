#!/bin/bash
set -xeuo pipefail

RELEASE=''

while [[ $# -gt 0 ]]
do
  key=$1
  case $key in
    -r|--release)
    RELEASE=$2
    shift # past argument
    shift # past value
    ;;
  esac
done

if [[ $RELEASE == "" ]]
then
  echo "No release specified"
  exit
fi

echo "Preparing release $RELEASE"

sed -i "s/\[Unreleased\]/[$RELEASE] - $(date +'%Y-%m-%d')/g" CHANGELOG.md
sed -i "s/awsigenomesbuild-[0-9\.]\+/awsigenomesbuild-$RELEASE/g" Dockerfile
sed -i "s/awsigenomesbuild-[0-9\.]\+/awsigenomesbuild-$RELEASE/g" environment.yml
sed -i "s/version = '[0-9\.]\+'/version = '$RELEASE'/g" nextflow.config
sed -i "s/awsigenomesbuild:[0-9\.]\+/awsigenomesbuild:$RELEASE/g" nextflow.config

git commit CHANGELOG.md Dockerfile environment.yml nextflow.config -m "preparing release $RELEASE [skip ci]"
