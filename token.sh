# Get new token
token=""
message="New token: "
read -p "$message" token

# Get username
username=""
message="Username: "
read -p "$message" username

sed -i "s|\($username:\)[^@]*@|\1$token@|" .git/config
