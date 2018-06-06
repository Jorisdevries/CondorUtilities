#!/bin/bash

# Example usage: `source makeXml.sh "/r05/dune/mcproduction_v05_04_00/prodgenie_bnb_nu_uboone_100k/*reco1.pndr" "PandoraSettings_Master" "PandoraSettings_Neutrino" "PandoraSettings_Cosmic" "master_xmls" "neutrino_xmls" "cosmic_xmls" "root" "roots"`

# Grab the input parameters.
source_dir=$1
master_xml_label=$2
neutrino_xml_label=$3
cosmic_xml_label=$4
master_xml_dir=$5
neutrino_xml_dir=$6
cosmic_xml_dir=$7
root_label=$8
root_dir=$9

# Get rid of any existing xml files.
rm -f neutrino_xmls/*.xml
rm -f cosmic_xmls/*.xml
rm -f master_xmls/*.xml

counter=0

for i in `ls ${source_dir} | sort -V`
do
    # Get the file identifier and use this for the output root files.
    fileIdentifier=$counter # $[`echo $i | grep -oP '(?<=_)\d+(?=_reco1\.)'`]
    outputFile=$(pwd)/${root_dir}/${root_label}_$fileIdentifier.root;

    # Use sed to replace INPUT_FILE_NAME, NEUTRINO_SETTINGS_FILE and COSMIC_SETTINGS_FILE in the Master XML file with the right paths.
    sed -e s,INPUT_FILE_NAME,$i, -e s,NEUTRINO_SETTINGS_FILE,$(pwd)/${neutrino_xml_dir}/PandoraSettings_Neutrino_${fileIdentifier}.xml, -e s,COSMIC_SETTINGS_FILE,$(pwd)/${cosmic_xml_dir}/PandoraSettings_Cosmic_${fileIdentifier}.xml, ${master_xml_label} > $(pwd)/${master_xml_dir}/PandoraSettings_Master_${fileIdentifier}.xml

    #Propagate OUTPUT_FILE_NAME and FILE_IDENTIFIER to both Neutrino and Cosmic settings files
    sed -e s,OUTPUT_FILE_NAME,$outputFile, -e s,FILE_IDENTIFIER,$fileIdentifier, ${neutrino_xml_label} > $(pwd)/${neutrino_xml_dir}/PandoraSettings_Neutrino_${fileIdentifier}.xml
    sed -e s,OUTPUT_FILE_NAME,$outputFile, -e s,FILE_IDENTIFIER,$fileIdentifier, ${cosmic_xml_label} > $(pwd)/${cosmic_xml_dir}/PandoraSettings_Cosmic_${fileIdentifier}.xml

    counter=$[$counter+1]
    echo -ne " > Writing all settings files for file number: ${fileIdentifier}."\\r
done
echo -ne \\n
