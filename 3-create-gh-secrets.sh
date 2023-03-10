#!/bin/bash

set -e pipefail

keyvault=$(cat terraform/output.json| jq --raw-output '.keyvault.value')

if [ -z $keyvault ]; then
    echo "Could not find keyvault. Stopping!"
    exit 1
fi

if [ -z $githubmail ]; then
    echo "Could not find githubmail. Stopping!"
    exit 1
fi

if [ -z $githubpat ]; then
    echo "Could not find githubpat. Stopping!"
    exit 1
fi

if [ -z $githubtrigger ]; then
    echo "Could not find githubtrigger. Stopping!"
    exit 1
fi

echo "Found all properties. Checking secrets now."

tempdir=$(mktemp -d)

ssh-keygen -t ed25519 -C $githubmail -f $tempdir/gh-key -q -N ""
ssh-keyscan -t rsa github.com > $tempdir/known_hosts 2> /dev/null

az keyvault secret show  -n github-private-key --vault-name $keyvault > /dev/null 2> /dev/null      || az keyvault secret set -f $tempdir/gh-key -n github-private-key --vault-name $keyvault > /dev/null
az keyvault secret show  -n github-public-key --vault-name $keyvault > /dev/null 2> /dev/null       || az keyvault secret set -f $tempdir/gh-key.pub -n github-public-key --vault-name $keyvault > /dev/null
az keyvault secret show  -n github-known-hosts --vault-name $keyvault > /dev/null 2> /dev/null      || az keyvault secret set -f $tempdir/known_hosts -n github-known-hosts --vault-name $keyvault > /dev/null
az keyvault secret show  -n github-pat --vault-name $keyvault > /dev/null 2> /dev/null              || az keyvault secret set --value $githubpat -n github-pat --vault-name $keyvault > /dev/null
az keyvault secret show  -n github-trigger-secret --vault-name $keyvault > /dev/null 2> /dev/null   || az keyvault secret set --value $githubtrigger -n github-trigger-secret --vault-name $keyvault > /dev/null

echo "Upload public key to github:"
az keyvault secret show  -n github-public-key --vault-name kvrenovate-talk | jq --raw-output ".value"

rm -rf $tempdir