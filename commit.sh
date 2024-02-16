# check if there are any changes
if [ -z "$(git status --porcelain)" ]; then 
    echo "No changes to commit"
    exit 0
fi


# check if there are any tracked files to commit A D M R C U
if [ -z "$(git diff --staged --name-only | awk 'NR>=0 && NR<=999')" ]; then 
    echo "No tracked files to commit"
else
    echo "Tracked files found. Please enter commit message"
    # get the filename of the file
    list=$(git diff --staged --name-only | awk 'NR>=0 && NR<=999')
    
    # get the diff of the file
    git diff --staged -- $file

    # commit all files one by one
    for file in $list
    do
        echo "Want to commit $file now? (y/n)"
        read answer
        if [ "$answer" == "y" ]; then
            git commit -e
        else
            exit 0
        fi
    done
fi


# check if there are any file to commit
if [ -z "$(git status --porcelain)" ]; then 
    echo "No changes to commit"
    exit 0
else
    echo "There are still changes to commit"
    list=$(git status --porcelain | awk '{print $2}')
    for file in $list
    do
        git diff HEAD $file

        echo "Want to commit $file now? (y/n)"
        read answer
        if [ "$answer" == "y" ]; then
            git add $file
            # add git diff HEAD $file to the commit message with -e and commented out
            git commit -e
        else
            exit 0
        fi
    done
fi

