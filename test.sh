TOKEN=<insert_your_osio_token>

NAME=<workspace_name>

id=$(curl -L -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data '{"defaultEnv":"'$NAME'","environments":{"'$NAME'":{"machines":{"dev-machine":{"attributes":{"memoryLimitBytes":"2147483648"},"servers":{"5000/tcp":{"attributes":{},"port":"5000","protocol":"http"},"3000/tcp":{"attributes":{},"port":"3000","protocol":"http"},"8080/tcp":{"attributes":{},"port":"8080","protocol":"http"},"9000/tcp":{"attributes":{},"port":"9000","protocol":"http"}},"volumes":{},"installers":["org.eclipse.che.exec","org.eclipse.che.terminal","org.eclipse.che.ws-agent","com.redhat.bayesian.lsp","com.redhat.oc-login"],"env":{}}},"recipe":{"type":"dockerimage","content":"registry.devshift.net/che/centos-nodejs"}}},"projects":[{"links":[],"name":"nodejs-hello-world","attributes":{"language":["javascript"]},"type":"node-js","source":{"location":"https://github.com/che-samples/web-nodejs-sample.git","type":"git","parameters":{}},"path":"/nodejs-hello-world","description":"Simple NodeJS Project.","problems":[],"mixins":[]}],"name":"'$NAME'","attributes":{},"commands":[{"commandLine":"cd ${current.project.path} \u0026\u0026 node app/app.js","name":"run","attributes":{"goal":"Run","previewUrl":"${server.8080/tcp}"},"type":"custom"},{"commandLine":"cd ${current.project.path} \nnode app/app.js","name":"nodejs-hello-world:run","attributes":{"goal":"Run","previewUrl":"${server.3000/tcp}"},"type":"custom"}],"links":[]}' https://che.openshift.io/api/workspace | jq .id)

id=$(echo $id | cut -d'"' -f 2)
echo $id
echo "***Running workspace***"
curl -X POST --header 'Accept: application/json' --header "Authorization: Bearer $TOKEN" https://che.openshift.io/api/workspace/$id/runtime

echo
echo "***Getting wkspc info:***"
curl -X GET --header 'Accept: application/json' --header "Authorization: Bearer $TOKEN" https://che.openshift.io/api/workspace/$id 

echo
echo "***Getting url:***"
url=$(curl -X GET --header 'Accept: application/json' --header "Authorization: Bearer $TOKEN" https://che.openshift.io/api/workspace/$id | jq '.runtime.machines["dev-machine"].servers["exec-agent/http"].url')

url=$(echo $url | cut -d'"' -f 2)
echo $url

while true; do
	curl -s -o /dev/null -w "%{http_code}" ${url}
	echo
done

