# Django on Docker

This repo was created using the fine article [Dockerizing Django with Postgres, Gunicorn, and Nginx](https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/) byMichael Herman from the great testdriven.io site.

I will not repeat all the details for this, but note where I found differences in my workflow, and add clarification.

The above article seems like its aimed at more advanced users, so doesn't cover every exact step.  And, exact steps depend on the system and version of tools you will use.  I also want this as a reference for spinning up new Django instances, so my goal his is to be a bit more detailed and leave a good trail to follow.  To see the exact contents of the Docker and other required files see the article link above.

I will be attempting to complete all three in the Django on Docker Series

1. Dockerizing Django with Postgres, Gunicorn, and Nginx
2. Securing a Containerized Django Application with Let's Encrypt
3. Deploying Django to AWS with Docker and Let's Encrypt (this tutorial!)

## Workflow

This is the collection of commands I use to work on this repo.  Skip this to see the narrative on how to create it from scratch.

These commands are for VSCode bash terminal and will be different depending on the system used.

Use the venv to install packages:

```sh
python -m venv env
source env/Scripts/activate
pip install xyz
deactivate
pip freeze --local > requirements.txt # the article uses a manual approach to this so not sure if we will use it here
```

### Local commands

```sh
docker-compose build
docker-compose -f docker-compose.prod.yml up -d --build # for prod
docker run -d <volume> # what is this for?
docker-compose up # run the containers
docker-compose down -v # bring down the containers and the associated volumes
```

### Prod versions

```sh
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d --build
docker-compose -f docker-compose.prod.yml exec web python manage.py migrate --noinput
```

## Versions & Systems

Article dependencies:

- Django v4.2.3
- Docker v24.0.2
- Python v3.11.4

What I usually use:

- Python 3.10.8 or 3.9.17
- Django version 3.2.

I will stick with Python 3.10.11.

I am on a Windows 11 laptop.  However, I've found with Python there are different lib versions available for other systems like Mac and Linux.  Apparently Nginx works best with Linux, so eventually I will want to deploy this to EC2,  which means having a container that also uses Linux to develop on could save us later from strange errors.  I found out first hand when trying to deploy my [Pytorch Django React project](https://github.com/timofeysie/pytorch_django_react) in an EC2 instance based on Windows 11 and how much the manual approach to deployment sucks, which is why I'm here getting things right from the start now.

### Creating the projectI thou

Here are the first steps from the article:

```sh
$ mkdir django-on-docker && cd django-on-docker
$ mkdir app && cd app
$ python3.11 -m venv env
$ source env/bin/activate
(env)$

(env)$ pip install django==4.2.3
(env)$ django-admin startproject hello_django .
(env)$ python manage.py migrate
(env)$ python manage.py runserver
deactivate
```

### The virtual environment

To enable a [virtual environment in Python](https://realpython.com/python-virtual-environments-a-primer), there might be different commands for different systems.

There are three commands needed, create, activate and deactivate.  The article shows this:

```sh
python3.11 -m venv env
```

I don't use this approach when using Python.  I have one version on my system, Python 3.10.11, and I will use that.

I believe this is the command I used to create the venv:

```sh
python3.11 -m venv env
```

I initially started off in a Windows command prompt, just because that's what I do to initiate projects.

```sh
source env/bin/activate
source : The term 'source' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ source env/bin/activate
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (source:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

After this I open the directory in my editor and continue from there.  For Windows 11 with bash in VSCode:

```sh
source env/Scripts/activate
```

I had to make some changes to the app\docker-compose.yml file based on errors like this:

```sh
$ docker-compose build
time="2024-05-19T19:09:26+10:00" level=warning msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.yml: `version` is obsolete"
2024/05/19 19:09:26 http2: server: error reading preface from client //./pipe/docker_engine: file has already been closed
2024/05/19 19:09:26 http2: server: error reading preface from client //./pipe/docker_engine: file has already been closed
[+] Building 0.0s (0/0)                                                                                                                                  docker:default
unable to prepare context: path "C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\app" not found
```

I changed version: '3.8' -> 3.9

And fix the yml file build directory page.

## PostgreSQL

I forgot to engage the virtual environment when I installed the [Psycopg PostgreSQL adapter](https://www.psycopg.org/) for Python.  So I decided to uninstall it and then do it correctly.

```sh
pip list
psycopg                       3.1.19
psycopg2                      2.9.9
pip uninstall psycopg==3.1.19
pip uninstall psycopg2==2.9.9
```

I can use the existing virtual environment created previously:

```sh
pip install psycopg
```

Then exit the virtual environment.

```sh
deactivate
```

When I installed psycopg, it said: psycopg 3.1.19 and psycopg2 2.9.9

In the article, it says to add Psycopg2 to requirements.txt:  psycopg2-binary==2.9.6

I'm going to use the newer version with the binary name for now.  Hope that's OK.

docker-compose up -d --build
docker-compose exec web python manage.py migrate --noinput

Ensure the default Django tables were created:

$ docker-compose exec db psql --username=hello_django --dbname=hello_django_dev

Here are the commands shown for working with the command line interface for Postgres:

```sh
\l
\c hello_django_dev
\dt
\q
```

Check that the volume was created by running:

```sh
docker volume inspect django-on-docker_postgres_data
```

After the successful commands in the postgres shell, I may have forgotton to exit the venv:

```sh
$ docker volume inspect django-on-docker_postgres_data
[]
Error response from daemon: get django-on-docker_postgres_data: no such volume
(env)
```

But after deactivating it, the error is the same.

This is what volumes I see now:

```sh
$ docker volume ls
local     app_postgres_data
```

So my inspect command should be:

```sh
$ docker volume inspect app_postgres_data
[
    {
        "CreatedAt": "2024-05-19T12:54:53Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "app",
            "com.docker.compose.version": "2.26.1",
            "com.docker.compose.volume": "postgres_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/app_postgres_data/_data",
        "Name": "app_postgres_data",
        "Options": null,
        "Scope": "local"
    }
]
```

Here is what is shown in the article:

```sh
[
    {
        "CreatedAt": "2023-07-20T14:15:27Z",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.project": "django-on-docker",
            "com.docker.compose.version": "2.19.1",
            "com.docker.compose.volume": "postgres_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/django-on-docker_postgres_data/_data",
        "Name": "django-on-docker_postgres_data",
        "Options": null,
        "Scope": "local"
    }
]
```

How did the article name appear to be a combination of these two names: "django-on-docker_postgres_data"?

Well, the repo is called django-on-docker, so the author might have some mistakes in the article.

Next, add an entrypoint.sh file to the "app" directory to verify that Postgres is healthy before applying the migrations and running the Django development server:

### entrypoint.sh

I'm not really sure why this is needed:

```sh
#!/bin/sh

if [ "$DATABASE" = "postgres" ]
then
    echo "Waiting for postgres..."

    while ! nc -z $SQL_HOST $SQL_PORT; do
      sleep 0.1
    done

    echo "PostgreSQL started"
fi

python manage.py flush --no-input
python manage.py migrate

exec "$@"
```

It's purpose is to verify that Postgres is healthy before applying the migrations and running the dev server.

In a note about the flush & migrate lines the article says you may want to comment them out so they don't run on every container start or re-start, but it doesn't explain why you would want to do this.

I actually had to change the while statement to avoid the error ```web-1 | /usr/src/app/entrypoint.sh: 7: /usr/src/app/entrypoint.sh: nc: not found```:

```sh
    # Check network connectivity to the PostgreSQL host and port
    while ! timeout 1 bash -c "echo > /dev/tcp/$SQL_HOST/$SQL_PORT"; do
      sleep 0.1
    done
```

### Run the containers

There are few more steps as listed here:

- add an entrypoint.sh file to the "app" directory to verify that Postgres is healthy before applying the migrations and running the Django development server and Update the file permissions locally.
- update the Dockerfile to copy over the entrypoint.sh file and run it as the Docker entrypoint command
- Run the containers with ```docker-compose up```

Then goto:  http://127.0.0.1:8000/

And it's running again and connected to the db.  Congrats.

## Gunicorn

What is this for?  It says Gunicorn is a production-grade WSGI (Web Server Gateway Interface) server for production environments.  In my previous DRF projects, it was used when deploying to Heroku, but I was never given a reason as to why it was needed.  When it comes to servers, I thought the whole point was to use Nginx, but I want to understand how (and why) Gunicorn is required and used.

The article does provide [the WSGI chapter](https://testdriven.io/courses/python-web-framework/wsgi/) from the [Building Your Own Python Web Framework](https://testdriven.io/courses/python-web-framework/) course which should answer all our questions.

WSGI - a SET OF RULES for a web server and a web application.

For now, we manually include it in the requirements.txt file: ```gunicorn==21.2.0```

Again, in the past I would install packages with pip and run ```pip freeze --local > requirements.txt```.  I'm not sure why that is not done here, except maybe it is so the exact version is used in the Docker container.

To use Django's built-in server in dev we create docker-compose.prod.yml and .env.prod for prod and use the current one for dev.

I am using version 3.9 here as before, but not sure what changes I might have to make to the path or app name as I did before when fixing the docker-compose.yml file.

The big difference is the command to run the server.

Running locally: ```command: python manage.py runserver 0.0.0.0:8000```

Running in prod: ```command: gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000```

Add that name of the app to the list of names of the app so far:

- app_postgres
- app_postgres_data
- django-on-docker
- django-on-docker_postgres_data
- hello_django

I thought hello_django was only the postgres db name and user.

Anyhow, back to the changes needed to the path, this is the error I see:

```sh
$ docker-compose down -v
time="2024-05-22T06:58:17+10:00" level=warning msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.yml: `version` is obsolete"
[+] Running 4/4
 ✔ Container app-web-1       Removed 
 ✔ Container app-db-1        Removed
 ✔ Volume app_postgres_data  Removed
 ✔ Network app_default       Removed
$ docker-compose -f docker-compose.prod.yml up -d --build
time="2024-05-22T06:58:31+10:00" level=warning msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.prod.yml: `version` is obsolete"
[+] Building 0.0s (0/0)  docker:default
[+] Building 0.0s (0/0)                                                                                                                            docker:default
unable to prepare context: path "C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\app" not found
```

from this:

```sh
services:
  web:
    build: ./app
    command: gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000
```

to this:

```sh
services:
  web:
    build:
      context: .  # this solves the issue
    command: gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000
```

The big difference is the ```context: .```  adjusted build context path.

Now the containers run and here is the wonderful output:

```sh
$ docker-compose -f docker-compose.prod.yml up -d --build
time="2024-05-22T07:08:07+10:00" level=warning msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.prod.yml: `version` is obsolete"
2024/05/22 07:08:07 http2: server: error reading preface from client //./pipe/docker_engine: file has already been closed
[+] Building 0.0s (0/0)                                                                                                                            docker:default
resolve : CreateFile C:\Users\timof\repos\django\django-on-docker\app\app: The system cannot find the file specified.
timof@BOOK-ANH52UMLGO MINGW64 ~/repos/django/django-on-docker/app (main)
$ docker-compose -f docker-compose.prod.yml up -d --build
time="2024-05-22T07:08:48+10:00" 
level=warning 
msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.prod.yml: `version` is obsolete"
[+] Building 8.5s (14/14) FINISHED                                                                                                                 docker:default
 => [web internal] load build definition from Dockerfile
 => => transferring dockerfile: 583B
 => [web internal] load metadata for docker.io/library/python:3.11.4-slim-buster
 => [web internal] load .dockerignore
 => => transferring context: 2B
 => [web 1/9] FROM docker.io/library/python:3.11.4-slim-buster@sha256:c46b0ae5728c2247b99903098ade3176a58e274d9c7d2efeaaab3e0621a53935
 => [web internal] load build context
 => => transferring context: 1.69MB
 => CACHED [web 2/9] WORKDIR /usr/src/app
 => CACHED [web 3/9] RUN pip install --upgrade pip
 => CACHED [web 4/9] COPY ./requirements.txt .
 => CACHED [web 5/9] RUN pip install -r requirements.txt
 => [web 6/9] COPY ./entrypoint.sh .
 => [web 7/9] RUN sed -i 's/\r$//g' /usr/src/app/entrypoint.sh
 => [web 8/9] RUN chmod +x /usr/src/app/entrypoint.sh
 => [web 9/9] COPY . . 
 => [web] exporting to image
 => => exporting layers
 => => writing image sha256:514ef9692dfe73221665d4b54e0b84d16b431966e07c453d84558d74b8d21db
 => => naming to docker.io/library/app-web
[+] Running 4/4
 ✔ Network app_default         Created
 ✔ Volume "app_postgres_data"  Created 
 ✔ Container app-db-1          Started
 ✔ Container app-web-1         Started
 ```

 So we might not even need the version line in those yml files.

 Next, the article shows creating a new entrypoint file for production ```entrypoint.prod.sh``` and a giant ```Dockerfile.prod``` for a multi-stage build to reduce the final image size.

About this it says:  *Essentially, builder is a temporary image that's used for building the Python wheels. The wheels are then copied over to the final production image and the builder image is discarded.*

Wait, what?  The Python wheels?

Try it out:

```sh
$ docker-compose -f docker-compose.prod.yml down -v
$ docker-compose -f docker-compose.prod.yml up -d --build
$ docker-compose -f docker-compose.prod.yml exec web python manage.py migrate --noinput
```

However, in the up command, I see an issue:

```sh
$ docker-compose -f docker-compose.prod.yml up -d --build
time="2024-05-22T07:24:42+10:00" level=warning msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.prod.yml: `version` is obsolete"
[+] Building 6.1s (15/27)                                                                                                                          docker:default
 => [web internal] load build definition from Dockerfile.prod
 => => transferring dockerfile: 1.70kB
 => [web internal] load metadata for docker.io/library/python:3.11.4-slim-buster  
...
11.57 ./env/Lib/site-packages/setuptools/_vendor/pyparsing/__init__.py:165:1: F405 'OpAssoc' may be undefined, or defined from star imports: .actions, .core, .exceptions, .helpers, .results, .util
... thousands of similar errors
16.29 ./env/Lib/site-packages/typing_extensions.py:3233:13: W503 line break before binary operator
------
failed to solve: process "/bin/sh -c flake8 --ignore=E501,F401 ." did not complete successfully: exit code: 1
```

ChatGPT wants me to open that file and fix all the flak8 errors.  I cannot as it says "review the error messages and fix any coding style or convention violations" because it contains thousands of errors, I have two day jobs, and I did not create this file in the first place.

There must be another way to resolve this error.  So I simply comment out the flake8 commands in the Dockerfile.prod and the containers run.

The next issues:

```sh
$ docker-compose -f docker-compose.prod.yml up -d --build
[+] Running 4/4
 ✔ Network app_default         Created
 ✔ Volume "app_postgres_data"  Created
 ✔ Container app-db-1          Started
 ✔ Container app-web-1         Started
$  docker-compose -f docker-compose.prod.yml exec web python manage.py migrate --noinput
time="2024-05-22T07:54:20+10:00" level=warning msg="C:\\Users\\timof\\repos\\django\\django-on-docker\\app\\docker-compose.prod.yml: `version` is obsolete"
service "web" is not running
```

```sh
$ docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS          PORTS      NAMES
8ddcdfd9fa30   postgres:15   "docker-entrypoint.s…"   11 minutes ago   Up 11 minutes   5432/tcp   app-db-1
$ docker ps -a
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS                        PORTS                    NAMES
00d5bed91ed2   app-web                 "/home/app/web/entry…"   12 minutes ago   Exited (127) 12 minutes ago                            app-web-1
8ddcdfd9fa30   postgres:15             "docker-entrypoint.s…"   12 minutes ago   Up 12 minutes                 5432/tcp                 app-db-1
347a52141309   postgres                "docker-entrypoint.s…"   11 hours ago     Exited (1) 11 hours ago                                friendly_franklin
4687bf223246   postgres                "docker-entrypoint.s…"   11 hours ago     Exited (1) 11 hours ago                                hopeful_shockley
e4bcf10d319f   django-gitlab-ec2-web   "/usr/src/app/entryp…"   3 weeks ago      Exited (255) 2 days ago       0.0.0.0:8000->8000/tcp   django-gitlab-ec2-web-1   
0c4e3e2ecf17   postgres:15             "docker-entrypoint.s…"   3 weeks ago      Exited (255) 2 days ago       5432/tcp                 django-gitlab-ec2-db-1
$ docker logs app-web-1
Waiting for postgres...
PostgreSQL started
/home/app/web/entrypoint.prod.sh: 14: exec: gunicorn: not found
```

Apparently I forgot to install gunicorn.  Activate the even and ```pip install gunicorn==21.2.0``` and make sure it's in the requirments file.

Then the three commands shown above all work.

## Nginx

To update my question about Gunicorn vs. Nginx there is a bit more detail about the role of Nginx in this app.

Nginx acts as a reverse proxy for Gunicorn to handle client requests as well as serve up static files.

### Reverse Proxy

The article has [this link](https://www.f5.com/glossary/reverse-proxy) to explain the reverse proxy which I will I will describe a bit of here.

A proxy sits between the client and the server in order to manage requests and sometimes responses.

A reverse proxy sits in front of web servers and forwards client requests to the servers.

So this seems to explains what that are.  Next, why.

The reverse-proxy link then says: *The requested resources are returned to the client as if they originated from the proxy server itself.*

Does that mean the Gunicorn is a proxy, and Nginx is a reverse-proxy?

Why do we need a reverse proxy?  A reverse proxy also provides smooth flow of network traffic between clients and servers, and the ability to direct requests based on a wide variety of parameters such as user device, location, etc.

Sounds like a load balancer really.  What’s the Difference Between a Reverse Proxy and a Load Balancer then?

A load balancer distributes incoming client requests among a group of servers that all host the same content.

The reverse proxy as the public face of the website.  Some things it provides are increased security, scalability and flexibility as well as web acceleration.

So I'm still not exactly clear about the two servers.  I will continue for now with the setup and get back to this soon.
