#!/bin/bash

VERSION="1.3.0"
FOLDER="$HOME/.backup"
CONFIG_FILE="$HOME/.backup/backup.conf"
DEFAULT_LIST="$HOME/.backup/backup.list"
DEFAULT_BACKUP_LOCATION="$HOME/.backup/backup"
DEFAULT_BACKUP_COUNT=50

function PrintInfo {
    echo "Info : If you just installed this program"
    echo "          or if it is the first time running it as user $(whoami) please run 'backup -i'."
    echo "          to setup backup list use 'backup -e',"
    echo "          to run the backups use 'backup -R',"
    echo "          to atomatize operations combine with crontab."
    echo "          for more help 'backup -h' for error reporting: https://github.com/Reiikz/BashBackupScript/issues"
}

function PrintBackupFolderError {
    echo "Error: ¿did you just touch the backup folder?"
    echo "         or ¿is the script working incorrectly? (It could be just empty though)"
    echo ""
    PrintInfo
}

function CheckConfig {
    if [ ! -e $CONFIG_FILE ]
    then
        mkdir -p $(dirname $CONFIG_FILE)
        WriteConfigFile
    fi
    LoadConfig
    configChecked=1
    if [ ! -e $backup_list ]
    then
        mkdir -p $(dirname $backup_list)
        WriteBackupListExample
    fi
    user=$(whoami)
    chown $user:$user -R $backup_folder
    chmod 700 -R $backup_folder >/dev/null 2>&1
    chown $user:$user -R $(dirname $CONFIG_FILE)
    chmod 700 -R $(dirname $CONFIG_FILE) >/dev/null 2>&1
    chown $user:$user -R $(dirname $backup_list)
    chmod 700 -R $(dirname $backup_list) >/dev/null 2>&1
}

function LoadConfig {
    if [ ! -e $CONFIG_FILE ]
    then
        echo "Config file was missing"
        if [ ! -z "$configChecked" ]
        then
            echo "can not write config file"
            exit 0
        fi
        CheckConfig
    fi
    source $CONFIG_FILE
}

function CheckRoot {
    if [ "$(whoami)" != "root" ]
    then
        if [ -z "$SUDO_COMMAND" ]
        then
            echo "please run as root"
            exit 1
        fi
    fi
}

#function Install {
#    if [ "$0" == "$INSTALL_PATH" ]
#    then
#        echo "the program is already installed"
#    else
#        CheckRoot
#        echo "$(cat $0)" > $INSTALL_PATH
#        chmod +x $INSTALL_PATH
#    fi
#}

function WriteConfigFile {
    echo "Writing config on: $CONFIG_FILE"
    mkdir -p $DEFAULT_BACKUP_LOCATION
    echo "#where should the backups should be stored?" > $CONFIG_FILE
    echo "backup_folder=$DEFAULT_BACKUP_LOCATION" >> $CONFIG_FILE
    echo "" >> $CONFIG_FILE

    echo "#Where is located the file with the backup list?" >> $CONFIG_FILE
    echo "backup_list=\"$DEFAULT_LIST\"" >> $CONFIG_FILE
    chmod 700 $CONFIG_FILE
    echo "if no other prompt in between; operation complete!"
}

function WriteBackupListExample {
    echo "Writing backup list on: $DEFAULT_LIST"
    mkdir -p $DEFAULT_BACKUP_LOCATION
    echo "invalid" > $DEFAULT_LIST
    echo "this is an example of the backup list" >> $DEFAULT_LIST
    echo "this file should have only the paths and the backup file names" >> $DEFAULT_LIST
    echo "otherwise it'll be invalid" >> $DEFAULT_LIST
    echo "you have to write the name in the inmediate line the backup path" >> $DEFAULT_LIST
    echo "and then the maximum number of stored backups for that path" >> $DEFAULT_LIST
    echo "there should be no lines in between or extra linejumps 'cause the script will read it as another file" >> $DEFAULT_LIST
    echo "" >> $DEFAULT_LIST
    echo "like this:" >> $DEFAULT_LIST
    echo "" >> $DEFAULT_LIST
    echo "/fake/path" >> $DEFAULT_LIST
    echo "fake-file" >> $DEFAULT_LIST
    echo "20" >> $DEFAULT_LIST
    echo "/fake/path2" >> $DEFAULT_LIST
    echo "fake-file-2" >> $DEFAULT_LIST
    echo "25" >> $DEFAULT_LIST
    echo "/etc/apt" >> $DEFAULT_LIST
    echo "super_vaca_powers_config_backup" >> $DEFAULT_LIST
    echo "1000000" >> $DEFAULT_LIST
    echo "if no other prompt in between; operation complete!"
}

function PrintHelp {
    echo "Usage:"
    echo "  sudo ./backup -I                                                                installs the program"
    echo "  backup -R                                                                       run the configured backups"
    echo "  backup -b <backup-name> -f <file-path> [OPTIONAL]-n <max-copys>                 backs up a file for you"
    echo "  backup -r <backup-name>                                                         restore a backup"
    echo "  backup -l                                                                       lists all backups"
    echo "  backup -L <backup-name>                                                         lists all storedes versions"
    echo "  backup -d <backup-name>                                                         remove all backups"
    echo "  backup -D <backup-name>                                                         delete specific backup file"
    echo "  backup -c                                                                       cleans up all the data (erases everything)"
    echo "  backup -e                                                                       edit the list"
    echo "  backup -E                                                                       edit settings"
    echo "  backup -i                                                                       installs settings files"
    echo "  backup -v                                                                       Version"
    echo "  backup -g <output-path>                                                         returns the backup"
    echo "  backup -x <output-path>                                                         returns a specific backup"
    echo "  backup -P <output-file>                                                         packages all the backups and config and outputs the file"
    echo "  backup -S <input-file>                                                          imports backups and config"
    echo "  backup -w                                                                       se backup folder"
    echo "  backup -W                                                                       prints the backup folder location"
    echo "  backup -G <output-file>                                                         outputs a backup of all your backups for specific origin"
    echo "  backup -s <input-file>                                                          restores a backup all your backups for specific"
    echo "  backup -o also restores the configuration for that backup when combined with -s"
    echo "(you can combine -g <output-path> with -R or with -b <backup-name> -f <file-path>)"
    echo "Is recomended the use of absolute paths"
}

function PrintVersion {
    echo "backup command, version $VERSION"
    echo "Copyright (c) 2019"
    echo "License GNU/GPLv3"
    echo "Source on: https://github.com/Reiikz/BashBackupScript"
}

function LoadBackupList {
    readarray -t PathList < $backup_list
    if [ "${PathList[0]}" == "invalid" ]
    then
        echo ""
        echo "the path list file is the example one, please fix it, it is located at ->"
        echo "          $backup_list"
        echo "or you can use backup -e to directly open it"
        echo ""
        exit 0
    fi
}

function LoadBackupCfg {
    CheckConfig
    if [ -z "$RUN_UNSTORED_BACKUP" ]
    then
        LoadBackupList
    fi
    LoadConfig
}

function GetFile {
    folder=$1
    if [ ! -e "$folder" ]
    then
        echo "the backup $1 doesn't exist"
        echo "To list backups and see wich are there and the last update use 'backup -l'"
        echo "To list all backups for specific file use 'backup -L <backup-name>'"
        exit 0
    fi

    folderCount=$(wc -l $folder/backupFolders | cut -d' ' -f 1)
    if [ $folderCount == 1 ]
    then
        dateFile=$folder/backups-$(cat $folder/backupFolders)
        filesCount=$(wc -l $dateFile | cut -d' ' -f 1)
        date=$(cat $folder/backupFolders)
        if [ $filesCount == 1 ]
        then
            file=$(cat $dateFile)
        else
            readarray -t files < "$dateFile"
            i=0
            for item in ${files[@]}
            do
                echo "   File #$i: $item"
                echo "      created at: $(cat $item.time)"
                echo ""
                i=$(($i+1))
            done
            echo "Type the number of the file you wanna select"
            echo -n "then press [Enter]: "
            read number
            if [ -z $number ]
            then
                echo "Invalid input"
                exit 0
            fi
            if [ $number -gt $(($filesCount-1)) ]
            then
                echo "number too big"
                exit 0
            fi
            file=${files[$number]}
        fi
    else
        echo "Type de date of the copy you wanna select"
        echo -n "   Type the day and press [ENTER]: "
        read day
        echo -n "   Type the month and press [ENTER]: "
        read month
        echo -n "   Type the year and press [ENTER]: "
        read year
        date=$(date -d "$month/$day/$year" "+%d-%m-%Y")
        if [ ! -e "$folder/$date" ]
        then
            echo "that date doesn't exist"
            exit 0
        fi
        dateFile=$folder/backups-$date
        filesCount=$(wc -l $dateFile | cut -d' ' -f 1)
        if [ $filesCount == 1 ]
        then
            file=$(cat $dateFile)
        else
            readarray -t files < "$dateFile"
            i=0
            for item in ${files[@]}
            do
                echo "   File #$i: $item"
                i=$(($i+1))
            done
            echo "Type the number of the file you wanna select"
            echo -n "then press [Enter]: "
            read number
            if [ $number -gt $(($filesCount-1)) ]
            then
                echo "number too big"
                exit 0
            fi
            file=${files[$number]}
        fi
    fi
}

function DoBackup {
    i=0
    origin=""
    destination=""
    maxCopys=0
    infoFileFolders=""
    infoFileBackup=""
    folderName=""

    for item in ${PathList[@]}
    do
        case $i in

            0)
                origin="$item"
                i=$((i+1))
            ;;

            1)
                infoFileFolders="$backup_folder/$item/backupFolders"
                infoFileBackup="$backup_folder/$item/backups-$(date +%d-%m-%Y)"
                infoFileLastBackup="$backup_folder/$item/lastBackup"
                folderName="$item"
                destinationFolder="$backup_folder/$item/$(date +%d-%m-%Y)"
                destination="$destinationFolder/$item-$(date +%H-%M-%S).tar"
                mkdir -p $(dirname $destination)
                echo "$BACKUP_MODE" > "$backup_folder/$folderName/backupMode"
                echo "$(date "+%d/%m/%Y ::: %H:%M:%S")" > $destination.time
                echo "$(date "+%d-%m-%Y")" > $infoFileLastBackup
                echo "$(date "+%H:%M:%S")" > "$backup_folder/$item/lastTime"
                mkdir -p $destinationFolder
                
                echo "$origin" > "$backup_folder/$item/origin"
                                
                lastBackup=""
                if [ -e "$infoFileLastBackup" ]
                then
                    lastBackup=$(cat $infoFileLastBackup)
                fi

                date=$(date "+%d-%m-%Y")
                if [ ! -e "$infoFileFolders" ]
                then
                    echo "$date" >> $infoFileFolders
                else
                    alreadyHasIt=$(grep -F "$date" $infoFileFolders)
                    if [ -z "$alreadyHasIt" ]
                    then
                        echo "$date" >> $infoFileFolders
                    fi
                fi

                if [ ! -e "$infoFileBackup" ]
                then
                    echo "$destination" > $infoFileBackup
                else
                    echo "$destination" >> $infoFileBackup
                fi
                i=$((i+1))
            ;;

            2)
                maxCopys=$item
                echo ""
                echo "Backing up   : $origin"
                if [ ! -e "$origin" ]
                then

                    echo "Invalid backup path"
                    exit 0
                fi

                cd $(dirname $origin)
                tar -cf "$destination" "$(basename $origin)"

                if [ ! -z "$GetBackup" ]
                then
                    cp $destination $GetBackup
                fi

                numberOfDates=$(echo $(wc -l $infoFileFolders) | cut -d' ' -f 1)
                readarray -t dates < "$infoFileFolders"
                files=""
                copysToErase=0

                declare -A NumberOfFilesByDate
                totalNumber=0
                EraseExtraCopys $maxCopys $folderName
                i=0
            ;;

        esac

    done

}

function EraseExtraCopys {
    local maxCopys=$1
    local folderName=$2
    local folderPath=$backup_folder/$2
    cd $folderPath
    local folderCount=$(wc -l "backupFolders" | cut -d' ' -f 1)
    echo "Max copys    : $maxCopys"
    if [ $folderCount == 1 ]
    then
        local files
        date=$(cat "backupFolders")
        numberFilesOnFolder=$(wc -l "backups-$date" | cut -d' ' -f 1)
        echo "Backup Number: $numberFilesOnFolder"
        copysToErase=$(($numberFilesOnFolder-$maxCopys))
        if [ $copysToErase -gt 0 ]
        then
            readarray -t files < "backups-$date"
            erasedCopys=0
            rm "backups-$date"
            for file in ${files[@]}
            do
                if [ $erasedCopys -lt $copysToErase ]
                then
                    rm $file
                    rm "$file.time"
                    erasedCopys=$(($erasedCopys+1))
                else
                    echo "$file" >> "backups-$date"
                fi
            done
        fi
    else
        readarray -t folders < "backupFolders"
        declare -A numberFilesByDate
        totalFiles=0
        for date in ${folders[@]}
        do
            number=$(wc -l "backups-$date" | cut -d' ' -f 1)
            numberFilesByDate["$date"]=$number
            totalFiles=$(($number+$totalFiles))
        done
        echo "Backup Number: $totalFiles"
        if [ $totalFiles -gt $maxCopys ]
        then
            copysToErase=$(($totalFiles-$maxCopys))
            declare -A files
            for date in ${folders[@]}
            do
                readarray -t fileList < "backups-$date"
                for i in $( seq 0 $((${#fileList[@]}-1)) )
                do
                    files[$date,$i]=${fileList[$i]}
                done
            done
            erasedCopys=0
            declare -A erasedCopysOnDate
            erasedCopysOnDate["${folders[0]}"]=0
            dateNumber=0
            while [ $erasedCopys -lt $copysToErase ]
            do
                date=${folders[$dateNumber]}
                if [ ${erasedCopysOnDate[$date]} -lt ${numberFilesByDate[$date]} ]
                then
                    file=${files[$date,${erasedCopysOnDate[$date]}]}
                    rm $file
                    rm "$file.time"
                    grep -v "${files[$date,${erasedCopysOnDate[$date]}]}" "backups-$date" > temp
                    rm "backups-$date"
                    mv "temp" "backups-$date"
                    erasedCopysOnDate[${folders[$dateNumber]}]=$((${erasedCopysOnDate[$date]}+1))
                    erasedCopys=$(($erasedCopys+1))
                else
                    rmdir $date
                    rm "backups-$date"
                    grep -v "$date" "backupFolders" > temp
                    rm "backupFolders"
                    mv "temp" "backupFolders"
                    dateNumber=$(($dateNumber+1))
                    erasedCopysOnDate[${folders[$dateNumber]}]=0
                fi
            done
        fi
    fi
    if [ -z "$erasedCopys" ]
    then
        erasedCopys=0
    fi
    echo "Erased       : $erasedCopys old copy/s"
    echo "Last Backup  : $(cat $folderPath/lastBackup) ::: $(cat $folderPath/lastTime)"
}

function RestoreFile {
    LoadConfig
    origin=$(cat $1/origin)
    rm -rf "$origin"
    mkdir -p $(dirname $origin)
    tar -xf $2 --directory $(dirname $origin)
    echo "Restored file: $origin"
}

function Resotore {
    LoadConfig
    folder="$backup_folder/$1"
    GetFile $folder
    RestoreFile $folder $file
}

function ListAllBackups {
    LoadConfig
    echo ""
    for item in $backup_folder/*/
    do
        if [ ! -e $item ]
        then
            echo "$item not found"
            PrintBackupFolderError
            exit 0
        fi
        echo "Backup: $(basename $item)"
        #echo "  Last updated: $(cat $item/lastBackup)  $(cat $item/lastTime)"
        file=$(tail $item/backups-$(cat $item/lastBackup) --lines=1)
        echo "      $file"
        if [ ! -e "$file.time" ]
        then
            echo "file: $file.time"
            echo "      containg time at wich the file was created was missing, this could cause errors"
            PrintBackupFolderError
        fi
        echo "          created at: $(cat $file.time)"
    done
    echo ""
}

function ListBackups {
    LoadConfig
    echo ""
    folder="$backup_folder/$1"
    if [ ! -e $folder ]
    then
        echo "that backup doesn't exist"
        exit 0
    fi
    readarray -t dates < "$folder/backupFolders"
    echo ${dates[@]}
    echo "Backups of: $1:"
    for item in ${dates[@]}
    do
        echo "  On date $item:"
        readarray -t files < "$folder/backups-$item"
        for item2 in ${files[@]}
        do
            if [ ! -e "$item2.time" ]
            then
                echo "$item2.time  was missing, exiting.."
                exit 0
            fi
            echo "      File: $item2"
            echo "          Created at: $(cat $item2.time)"
            echo ""
        done
    done
    echo ""
    echo "Last backup was: $(tail $folder/backups-$(tail $folder/backupFolders --lines=1) --lines=1)"
    echo "On             : $(cat $folder/lastBackup) :at: $(cat $folder/lastTime)"
    echo ""
}

function GetEditor {
    LoadConfig
    if [ -z "$editor" ]
    then
        echo -n "Type the executable of your text editor and press [ENTER]: "
        read editor
        echo "the path to the editor is: $editor"
        echo -n "is that correct? [y/n]: "
        read response
        while [ "$response" != "y" ]
        do
            echo -n "Type the executable of your text editor and press [ENTER]: "
            read editor
            echo "the path to the editor is: $editor"
            echo -n "is that correct? [y/n]: "
            read response
        done
        echo "" >> $CONFIG_FILE
        echo "#your preferred textfile editor" >> $CONFIG_FILE
        echo "editor=$editor" >> $CONFIG_FILE
    fi
}

function EditList {
    GetEditor
    $editor $backup_list
}

function EditConfig {
    GetEditor
    $editor $CONFIG_FILE
}

function RemoveBackup {
    chmod 700 -R $FOLDER >/dev/null 2>&1
    LoadConfig
    folder=$backup_folder/$1
    if [ ! -e $folder ]
    then
        echo "that backup doesn't exist"
    else
        echo "you are about to delete all your backups on: $1"
        echo -n "are you sure? [YES/n]: "
        read response
        if [ "$response" == "YES" ]
        then
            rm -rf $folder
        else
            echo "You scared me :v"
        fi
    fi
}

function DeleteSpecificBackup {
    LoadConfig
    folder="$backup_folder/$1"
    if [ ! -e "$folder" ]
    then
        echo "that backup doesn't exist"
        exit 0
    fi
    GetFile $folder
    echo "Are you sure you wanna delete the folloing backup?:"
    echo "          $file"
    echo -n "[YEy/nO]: "
    read response
    if [ "$response" == "YES" ]
    then
        rm $file
        readarray -t files < "$folder/backups-$date"
        rm "$folder/backups-$date"
        for item in ${files[@]}
        do
            if [ -e "$item" ]
            then
                echo "$item" >> "$folder/backups-$date"
            fi
        done
    else
        exit 0
    fi
}

function ExportAll {
    LoadConfig
    echo "$(basename $CONFIG_FILE)" >> names
    echo "$(basename $backup_list)" >> names
    echo "$(basename $backup_folder)" >> names
    outputFile=$(realpath $1 -L)
    tar -cf $outputFile names
    rm names
    cd $(dirname $backup_folder)
    tar -f $outputFile -r $(basename $backup_folder)
    cd $(dirname $CONFIG_FILE)
    tar -f $outputFile -r $(basename "$CONFIG_FILE")
    cd $(dirname $backup_list)
    tar -f $outputFile -r $(basename "$backup_list")
}

function ImportAll {
    if [ ! -e "$1" ]
    then
        "the file $1 does not exist"
        exit 0
    fi
    tar -xf $1
    readarray -t names < "names"
    configFileName=${names[0]}
    tar -cf $1 $configFileName
    rm -rf $CONFIG_FILE
    mkdir -p $(dirname $CONFIG_FILE)
    mv $configFileName $CONFIG_FILE
    LoadConfig
    rm -rf $backup_list
    mv ${names[1]} $backup_list
    rm -rf $backup_folder
    mv ${names[2]} $backup_folder/
    rm -rf names
    rm $1
}

function OpenBackupFolder {
    LoadConfig
    if [ -z "$file_explorer" ]
    then
        echo -n "Type your file explorer and press [ENTER]: "
        read fileExplorer
        echo "" >> $CONFIG_FILE
        echo "#this is the executable of your file explorer, if you wanna use the terminal change it for cd" >> $CONFIG_FILE
        echo "#if you wanna use for example cinnamon's file explorer change it for \"nemo\"" >> $CONFIG_FILE
        echo "file_explorer=$fileExplorer" >> $CONFIG_FILE
        $fileExplorer $backup_folder
    else
        $file_explorer $backup_folder
    fi
}

function SaveBackupOfBuckups {
    LoadConfig
    pFolder=$(realpath -L $1)
    cd $backup_folder
    echo -n "Type the backup name and press [ENTER]: "
    read backup
    if [ ! -e "$backup" ]
    then
        echo "that backup doesn't exist"
    fi
    origin=$(cat $backup/origin)
    
    #get backup quantity
    LoadBackupList
    i=0
    now=0
    for item in ${backup_list[@]}
    do
        if [ $item == $origin ]
        then
            now=1
        fi

        if [ $now == 1 ]
        then
            if [ $i == 2 ]
            then
                quantity=$item
            fi
        fi

        if [ $i -lt 2 ]
        then
            i=$(($i+1))
        else
            i=0
        fi
    done

    if [ -z "$quantity"]
    then
        quantity=20
    fi

    echo "#!/bin/bash" >> info
    echo "origin=$origin" >> info
    echo "name=$backup" >> info
    echo "quantity=$quantity" >> info
    chmod +x info

    tar -cf $pFolder $backup info
    rm info
}

function RestoreBackupOfBackup {
    LoadConfig
    cd $(dirname $1)
    tar -xf $(basename $1)
    if [ ! -e "info" ]
    then
        echo "missing info file"
    fi
    chmod +x info
    source info
    mv $name $backup_folder
    if [ ! -z "$RESTORE_OLD_CFG" ]
    then
        rm info
    else
        LoadBackupList
        for item in ${backup_list[@]}
        do
            if [ $item == $origin ]
            then
                exists=1
            fi
        done

        if [ -z "$exists" ]
        then
            LoadConfig
            echo "$origin" >> $backup_list
            echo "$name" >> $backup_list
            echo "$quantity" >> $backup_list
        fi
        rm info
    fi

}

function ReturnBackup {
    ListAllBackups
    echo "please input the backup name you wanna restore"
    echo -n "then press [ENTER]: "
    read name
    GetFile $backup_folder/$name
    cp $file $1
}

function CheckFirstArgument {
    if [ "$notFirst" != "" ]; then
        echo ""
        echo "Operation argument must be the first one"
        echo ""
        exit 1
    fi
}

function GetBackup {
    LoadConfig
    if [ "$2" != "" ]; then
        name=$2
    else
        echo -n "Type the name of the backup and press [ENTER]: "
        read name
    fi
    folder=$backup_folder/$name
    echo "$folder"
    GetFile $folder
    cp $file $1
}

function ValidateDirectory {
    if [ ! -e $1 ]; then
        mkdir -p $1
    fi
    if [ ! -d $1 ]; then
        echo "provided path is already exists and is not directory"
    fi
}

if [ $# -eq 0 ]; then
    PrintInfo
    exit 0
fi

CheckConfig

operation=""
while [ "$1" != "" ]; do
    
    case $1 in
        -g|--export-backup)
            CheckFirstArgument
            operation="GetBackup"
            shift
            if [ "$1" == "" ]; then
                echo "missing argument, must be <filename.tar> <backupname>"
                exit 1
            else
                data=$1
            fi
            shift
            if [ "$1" == "" ]; then
                echo "missing argument, must be <filename.tar> <backupname>"
                exit 1
            else
                data="$data $1"
            fi
        ;;

        -R|--run-backup|--run)
            BACKUP_MODE="AUTOMATIC"
            CheckFirstArgument
            operation="DoBackup"
        ;;

        -b|--manual-backup)
            CheckFirstArgument
            operation="ManualBackup"
        ;;

        --output-folder)
            shift
            if [ "$1" == "" ]; then
                echo "missing argument"
                exit 1
            fi
            MB_FOLDER=$1
        ;;

        --target-path)
            shift
            if [ "$1" == "" ]; then
                echo "missing argument"
                exit 1
            fi
            MB_TARGET=$1
        ;;
        
        --backup-count)
            shift
            if [ "$1" == "" ]; then
                MB_COUNT=DEFAULT_BACKUP_COUNT
            else
                MB_COUNT=$1
            fi
        ;;

        --backup-name)
            shift
            if [ "$1" == "" ]; then
                echo "missing argument"
                exit 1
            fi
            MB_NAME=$1
        ;;

        -e|--edit-backup-list)
            operation="EditList"
        ;;

        --config-file)
            shift
            if [ "$1" == "" ]; then
                echo "missing argument"
                exit 1
            fi
            CONFIG_FILE=$1
            if [ ! -e "$1" ]; then
                echo -n "Supplied config file doesn't exist ¿create it? [Y/N]"
                read opt
                if [ "$opt" == "y" ] || [ "$opt" == "y" ]; then
                    WriteConfigFile
                else
                    exit 0
                fi
            fi
        ;;

        --backup-list)
            shift
            if [ "$1" == "" ]; then
                echo "missing argument"
                exit 1
            fi
            DEFAULT_LIST=$1
            if [ ! -e "$1" ]; then
                WriteBackupListExample
            fi
        ;;

        --backup-folder)
            shift
            if [ "$1" == "" ]; then
                echo "missing argument"
                exit 1
            fi
            if [ -e "$1" ] && [ ! -d "$1" ]; then
                echo "already exists and is a file"
                exit 1
            fi
            DEFAULT_BACKUP_LOCATION=$1
        ;;

        --uninstall-folder)
            CheckFirstArgument
            echo "About to erase $FOLDER"
            echo -n "[YES I'M FUCCKING SHURE/No]: "
            read opt
            if [ "$opt" == "YES I'M FUCCKING SHURE" ]; then
                echo -n "erase folder? [Y/N]: "
                read opt
                if [ "$opt" == "Y" ] || [ "$opt" == "y" ]; then
                    rm -rf $FOLDER
                fi
            fi
            exit 0
        ;;

        --install-defaults)
            CheckFirstArgument
            CheckConfig
            exit 0
        ;;

        -r|--restore)
            operation="Resotore"
            shift
            if [ "$1" == "" ]; then
                echo "usage: backup $1 <backup-name>"
                ListAllBackups
                exit 1
            fi
            data=$1
        ;;

        -l|--list-all-backups)
            operation="ListAllBackups"
        ;;

        -L|--list-backups)
            operation="ListBackups"
            shift
            if [ "$1" == "" ]; then
                echo "usage: backup $1 <backup-name>"
                ListAllBackups
                exit 1
            fi
            data=$1
        ;;

        -E|--edit-config)
            operation="EditConfig"
        ;;

        -h|-H|--help|h|help|HELP|H)
            operation="PrintHelp"
        ;;

        -d|--delete-backup)
            operation="RemoveBackup"
            if [ "$1" == "" ]; then
                echo "usage: backup $1 <backup-name>"
                ListAllBackups
                exit 1
            fi
            data=$1
        ;;

        -v|--version)
            operation="PrintVersion"
        ;;

        -D|--delete-backup-file)
            operation="DeleteSpecificBackup"
            if [ "$1" == "" ]; then
                echo "usage: backup $1 <backup-name>"
                ListAllBackups
                exit 1
            fi
            data=$1
        ;;

        

        *)
            echo "$1 not recognized option"
            echo 
            PrintInfo
            exit 0
        ;;
    esac
    shift
    notFirst=1
done

case $operation in
    
    ManualBackup)
        BACKUP_MODE="MANUAL"
        ValidateDirectory $MB_FOLDER
        if [ -Z $MB_COUNT ]; then
            MB_COUNT=$DEFAULT_BACKUP_COUNT
        fi
        backup_folder=$MB_FOLDER
        declare -a PathList=("$MB_TARGET" "$MB_NAME" "$MB_COUNT")
        DoBackup
        exit 0
    ;;

    DoBackup)
        LoadBackupCfg
        if [ ! -z $MB_FOLDER ]; then
            echo "WARNING: BACKUP FOLDER OVERRIDEN, OUTPUT TO-> $MB_FOLDER"
            backup_folder=$MB_FOLDER
        fi
        i=0
        c=0
        if [ ! -z $MB_COUNT ]; then
            echo "WARNING: BACKUP COUNT OVERRIDEN"
            for item in ${PathList[@]}; do
                if [ $i -eq 2 ]; then
                    i=0
                    PathList[$c]=$MB_COUNT
                fi
                c=$(($c+1))
                i=$(($i+1))
            done
        fi
        DoBackup
        exit 0
    ;;

    *)
        $operation $data
        exit 0
    ;;
esac