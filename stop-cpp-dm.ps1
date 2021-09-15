# Has to be authorized using:
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
$IMAGE="cpp-dm"

docker kill "${IMAGE}"
