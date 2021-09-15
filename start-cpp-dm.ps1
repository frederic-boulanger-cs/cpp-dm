# Has to be authorized using:
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
$REPO="fred0cs/"
$IMAGE="cpp-dm"
$TAG="2021"
$PORT="8443"
docker run --rm -d -p ${PORT}:8443 -v "${PWD}:/config/workspace:rw" --name "${IMAGE}" "${REPO}${IMAGE}:${TAG}"
Start-Sleep -s 5
Start http://localhost:${PORT}
