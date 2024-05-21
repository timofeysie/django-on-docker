# Django on Docker

This repo was created using the fine article [Dockerizing Django with Postgres, Gunicorn, and Nginx](https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/).

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
.\env\Scripts\activate
pip install xyz
deactivate
pip freeze --local > requirements.txt # the article uses a manual approach to this so not sure if we will use it here
```

```sh
docker-compose build
docker run -d <volume> # what is this for?
docker-compose up
```

## Versions & Systems

Article dependencies:

- Django v4.2.3
- Docker v24.0.2
- Python v3.11.4

What I usually use:
Python 3.10.8 = 3.9.17
Django version 3.2.

I will stick with Python 3.10.11
Stick with the tutorial for now.

I am on a Windows 11 laptop.  However, I've found with Python there are different lib versions available for other systems like Mac and Linux.  Apparently Nginx works best with Linux, so eventually I will want to deploy this to EC2,  which means having a container that also uses Linux to develop on could save us later from strange errors.  I found out first hand when trying to deploy my [Pytorch Django React project](https://github.com/timofeysie/pytorch_django_react) in an EC2 instance based on Windows 11 and how much the manual approach to deployment sucks, which is why I'm here getting things right from the start now.

### Creating the project

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

For now, we manually include it in the requirements.txt file: ```gunicorn==21.2.0```

Again, in the past I would install packages with pip and run ```pip freeze --local > requirements.txt```.  I'm not sure why that is not done here, except maybe it is so the exact version is used in the Docker container.
