# Buen-Aire-Backend 
This repo contains the code for the Buen Aire backend
## Table of Contents: 
* [Buen-Aire-Backend required installations]()
* [Buen-Aire-Frontend Repo]((https://github.com/mckadesorensen/Buen-Aire-Frontend)
  * [Github Repo](https://github.com/mckadesorensen/Buen-Aire-Frontend)
* [System Architecture](#system-architecture) - Components of Buen-Aire-Backend
* [Deploying The Backend](#Deploying-The-Buen-Aie)


## Required Software 
* Docker 
  * [Mac OSx installtion](https://docs.docker.com/docker-for-mac/install/)
  * [Windows installtion](https://docs.docker.com/docker-for-windows/install/)
  * [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
  * Other Linux distros - You're on Linux, I am sure you can figure it out lol
* Make
  * Mac OSx & Linux - It should already be installed    
  * TODO: Windows users will have to get into docker to use this 

TODO: Update Archtiure Diagram
## System Architecture
![buen_air_transparent](https://user-images.githubusercontent.com/49543713/112903316-ce42ab00-9093-11eb-9852-2bc323043616.png)

TODO: Update Archtiure Diagram
## Deploying The Buen Aie
![deployment_buen_air_transparent](https://user-images.githubusercontent.com/49543713/112903355-dbf83080-9093-11eb-9661-bec0dd72caee.png)

The diagram above is a overview of the deployment process. The [Makefile](https://github.com/mckadesorensen/Buen-Aire-Backend/blob/main/Makefile) does most of the heavy lifting.

1. In the terminal navigate to the `Buen-Aire-Backend` folder and run the following command to build the `Docker image`
```Terminal
make image
```

2. Run the following command to enter the docker container

```Terminal
make container-shell
```
After this command your terminal should look similar to this:
```Terminal 
bash-4.2$ 

```

3. Set env vars. 
```Terminal
source env.sh aws_profile deploy_name
```

4. First time deploying a stack (In this case, a stack is a backend with resources that have prefix of `deploy_name` in a particular `aws_profile`)
```
make all
```
Updating existing stack
```
make
```

