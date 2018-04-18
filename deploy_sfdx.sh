#!/bin/bash




SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# set me
if [ $# -ne 2 ]
then
    echo "Usage : deploy_sfdx.sh ScratchOrgAlias DevelopperHubAlias"
    exit 1
fi

SCRATCHORGALIAS=$1
DEVHUBALIAS=$2

echo "Creating a new ScratchOrg=$SCRATCHORGALIAS in the developper hub $DEVHUBALIAS"

sfdx force:org:create -s -f config/project-scratch-def.json -a $SCRATCHORGALIAS
read -p "------------- Finished, type enter to continue "

echo "Pushing all source code to the org $SCRATCHORGALIAS" 
sfdx force:source:push -u $SCRATCHORGALIAS
read -p "------------- Finished, type enter to continue " 

echo "Pushing test data into $SCRATCHORGALIAS" 
sfdx force:data:tree:import --plan ./data/*plan.json --targetusername $SCRATCHORGALIAS
read -p "------------- Finished, type enter to continue " 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=(${i//./ })
    echo permissionName=$permissionName
    sfdx force:user:permset:assign -n $permissionName -u $SCRATCHORGALIAS
done

echo "Generating password on $SCRATCHORGALIAS for Heroku Connect"
sfdx force:user:password:generate
sfdx force:org:display
read -p "------------- Finished, type enter to continue " 

echo "------------- Finished, Launching web browser !" 
sfdx force:org:open 
read -p "------------- Finished, now work on the Org and come back here to deploy to production " 


echo "Pulling changes " 
sfdx force:source:pull 
read -p "------------- Finished, type enter to continue " 

echo "Creating Meta Data api Package"
rm -rf mdapi_output_dir
mkdir mdapi_output_dir
sfdx force:source:convert -d mdapi_output_dir/ --packagename sf-alm-demo
read -p "------------- Finished, type enter to continue " 

echo "Sending Metadata Api Package to the $DEVHUBALIAS Organisation"
sfdx force:mdapi:deploy -d mdapi_output_dir  -u $DEVHUBALIAS -w 1
read -p "------------- Finished, type enter to continue " 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=(${i//./ })
    echo permissionName=$permissionName
    sfdx force:user:permset:assign -n $permissionName -u $DEVHUBALIAS
done

read -p "------------- Finished, type enter to continue " 