#!/bin/bash
/
# Grab the input parameters.
eventsPerFile=$1
config_file=$2
master_xml_dir="master_xmls"
neutrino_xml_dir="neutrino_xmls"
cosmic_xml_dir="cosmic_xmls"
root_label="root"
root_dir="roots"
nFilesPerJob=$3
validate=$4
validation_directory=$5
validation_filename=$6
setupScriptLocation=$7
validation_args=$8

echo "SETUP: $setupScriptLocation"

# Check that hadd and root are accessible.
command -v hadd >/dev/null 2>&1 || { echo -e >&2 "\e[1;31mError: 'hadd' is required but is not currently accessible. Please setup uboonecode\e[0m"; return 1; }

if $validate ; then
    command -v hadd >/dev/null 2>&1 || { echo -e >&2 "\e[1;31mError: 'root' is required but is not currently accessible. Please setup uboonecode\e[0m"; return 1; }
fi

# Try to work out if we're in the right directory.
if [ ! -d scripts ]; then
    echo -e >&2 "\e[1;31mError: Could not see a 'scripts' folder. This script must be run from the 'condor' directory only\e[0m"; 
    return 1;
fi

# Make the required directories if they don't already exist.
mkdir -p roots txts xml_bases master_xmls neutrino_xmls cosmic_xmls results catroots log

# Delete any existing concatenated ROOT and base XML files--and any existing results.
rm -f catroots/*
rm -f xml_bases/*
rm -f results/*

echo -e "\e[1;35mWriting xml base files for all batches\e[0m"
echo -e " > This may take a while..."

# Get the number of columns in the configuration file.
numColumns=$(awk --field-separator=" " "{ print NF }" $config_file | uniq)

# Delete all the existing xml base files (and backups).
rm -f xml_bases/*.xml
rm -f xml_bases/*.bak

firstTime=true
batchCounter=0

# For each row in the configuration file, except the header row, make an XML base file.
while IFS='' read -r line || [[ -n "$line" ]]; do
    if $firstTime ; then
        firstTime=false;
        continue;
    fi

    # Copy the master XML file into the base directory and use sed to make the replacements for each column.
    masterSettingsFileLocation=$(echo $line | awk "NR==1{print \$2}")
    neutrinoSettingsFileLocation=$(echo $line | awk "NR==1{print \$3}")
    cosmicSettingsFileLocation=$(echo $line | awk "NR==1{print \$4}")

    eval "cp $masterSettingsFileLocation xml_bases/Master_$batchCounter.xml" # settings file location could use a ~
    eval "cp $neutrinoSettingsFileLocation xml_bases/Neutrino_$batchCounter.xml" # settings file location could use a ~
    eval "cp $cosmicSettingsFileLocation xml_bases/Cosmic_$batchCounter.xml" # settings file location could use a ~

    for i in `seq 7 $numColumns`; # column 1 is the pandora location, column 2 is the master settings file to use, column 3 is the neutrino settings file to use, column 4 is the cosmic settings file to use, column 5 is the reconstruction option, 6 is the sample location, the rest are the replacements to make in the settings file
        do
            columnTitle=$(awk "NR==1{print \$$i}" $config_file)
            
            # Avoid wildcard expansion in sample location.
            set -f
            columnEntry=$(echo $line | awk "NR==1{print \$$i}")
            set +f

            sed -i.bak s/"£$columnTitle£"/$columnEntry/g xml_bases/Master_$batchCounter.xml
            sed -i.bak s/"£$columnTitle£"/$columnEntry/g xml_bases/Neutrino_$batchCounter.xml
            sed -i.bak s/"£$columnTitle£"/$columnEntry/g xml_bases/Cosmic_$batchCounter.xml
            
        done  

    batchCounter=$((batchCounter+1))

largestBatchNumber=$((batchCounter-1))

done < "$config_file"

# Now run all the batch instances.
firstTimeHeader=true
batchCounter=0

while IFS='' read -r line || [[ -n "$line" ]]; do
    if $firstTimeHeader ; then
        firstTimeHeader=false;
        continue;
    fi

    pandoraLocation=$(echo $line | awk "NR==1{print \$1}")
    recoOption=$(echo $line | awk "NR==1{print \$5}")

    # Avoid wildcard expansion in sample location.
    set -f
    sampleLocation=$(echo $line | awk "NR==1{print \$6}")
    set +f

    source scripts/runCondorBatchInstance.sh $batchCounter "$pandoraLocation" "$eventsPerFile" "$sampleLocation" "${master_xml_dir}" "${root_label}" "${root_dir}" "${nFilesPerJob}" "${validate}" "${validation_directory}" "${validation_filename}" "${validation_args}" "$largestBatchNumber" "$setupScriptLocation" "$recoOption" "${neutrino_xml_dir}" "${cosmic_xml_dir}" 

    batchCounter=$((batchCounter+1))
    
done < "$config_file" 
