
read -p "Do you want update the token? [y/n] " answer

if [ "$answer" != "y" ]; then
    exit 0
fi

token=$(gh auth token | awk '{print $1}')
echo "Gh: $token"

if [ -z "$token" ] || [ "$token" == "no" ]; then
    echo "Token is empty"
    echo "Please, enter the token manually"
    token=""
    message="Enter new token: "
    read -p "$message" token
fi

echo "New token: $token"

username=""
message="Username: "
read -p "$message" username

sed -i "s|\($username:\)[^@]*@|\1$token@|" .git/config
