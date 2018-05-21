#!/bin/bash

# Example usage: `source makeXml.sh "/r05/dune/mcproduction_v05_04_00/prodgenie_bnb_nu_uboone_100k/*reco1.pndr" "PandoraSettings_Master" "PandoraSettings_Neutrino" "master_xmls" "neutrino_xmls" "root" "roots"`

# Grab the input parameters.
source_dir=$1
master_xml_label=$2
neutrino_xml_label=$3
master_xml_dir=$4
neutrino_xml_dir=$5
root_label=$6
root_dir=$7

# Get rid of any existing xml files.
rm -f neutrino_xmls/*.xml
rm -f master_xmls/*.xml

counter=0

for i in `ls ${source_dir} | sort -V`
do
    # Get the file identifier and use this for the output root files.
    fileIdentifier=$counter # $[`echo $i | grep -oP '(?<=_)\d+(?=_reco1\.)'`]
    outputFile=$(pwd)/${root_dir}/${root_label}_$fileIdentifier.root;

    # Use sed to replace the INPUT_FILE_NAME and OUTPUT_FILE_NAME in the XML file with the right paths.
    sed -e s,INPUT_FILE_NAME,$i, -e s,NEUTRINO_SETTINGS_FILE,$(pwd)/${neutrino_xml_dir}/PandoraSettings_Neutrino_${fileIdentifier}.xml, ${master_xml_label} > $(pwd)/${master_xml_dir}/PandoraSettings_Master_${fileIdentifier}.xml
    sed -e s,OUTPUT_FILE_NAME,$outputFile, -e s,FILE_IDENTIFIER,$fileIdentifier, ${neutrino_xml_label} > $(pwd)/${neutrino_xml_dir}/PandoraSettings_Neutrino_${fileIdentifier}.xml

    counter=$[$counter+1]
    echo -ne " > Writing: PandoraSettings_Master/Neutrino_${fileIdentifier}.xml"\\r
done
echo -ne \\n
