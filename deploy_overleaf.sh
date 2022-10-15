set -euo pipefail

echo "Downloading overleaf..."
git clone https://github.com/overleaf/toolkit.git ./overleaf

########## cp -rf ./overleaf-bak ./overleaf

cd ./overleaf

echo "Configuring..."
mv ./bin/docker-compose ./bin/docker-compose.bak
sed 's/exec docker-compose/exec docker compose/g' ./bin/docker-compose.bak > ./bin/docker-compose
chmod +x ./bin/docker-compose

./bin/init

mv ./config/overleaf.rc ./config/overleaf.rc.bak
sed '/SHARELATEX_LISTEN_IP/ c SHARELATEX_LISTEN_IP=0.0.0.0' ./config/overleaf.rc.bak | sed '/SHARELATEX_PORT/ c SHARELATEX_PORT=9002' > ./config/overleaf.rc

echo "version: '2.2'
services:
    sharelatex:
        environment:
            PATH: \"/usr/local/texlive/2022/bin/`uname -i`-linux:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"" > ./config/docker-compose.override.yml

echo "Starting container..."
./bin/up -d

echo "Updating LaTeX dependencies..."
./bin/docker-compose exec sharelatex tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet
set +e
./bin/docker-compose exec sharelatex tlmgr install scheme-full

set -e
echo "Generating new docker image sharelatex/sharelatex:with-texlive-full"
docker commit sharelatex sharelatex/sharelatex:with-texlive-full

echo "version: '2.2'
services:
    sharelatex:
        image: sharelatex/sharelatex:with-texlive-full
	environment:
	    PATH: \"/usr/local/texlive/2022/bin/`uname -i`-linux:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"" > ./config/docker-compose.override.yml

echo "Restarting services with new image..."
./bin/stop && ./bin/docker-compose rm -f sharelatex && ./bin/up -d

echo "Finished. "
HOSTNAME_LOCAL=$(cat /etc/hostname)
echo "In a browser, open http://${HOSTNAME_LOCAL}:9002/launchpad. You should see a form with email and password fields. Fill these in with the credentials you want to use as the admin account, then click Register.

Then click the link to go to the login page (http://${HOSTNAME_LOCAL}:9002/login). Enter the credentials. Once you are logged in, you will be taken to a welcome page.

Click the green button at the bottom of the page to start using Overleaf.

To start the container, just run './overleaf/bin/up -d'."
