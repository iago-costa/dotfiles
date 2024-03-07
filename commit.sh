# check if there are any changes
if [ -z "$(git status --porcelain)" ]; then 
    echo "No changes to commit"
    exit 0
fi

echo "Have changes to commit"
# get list of files to commit
list=$(git status -s | grep '' | awk '{print $2}')

# commit all files one by one
for file in $list
do
    git add $file
    
    # get the diff of the file
    git diff --staged -- $file

    git commit -e
done



