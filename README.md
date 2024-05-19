# Django on Docker

This repo was created using the fine article [Dockerizing Django with Postgres, Gunicorn, and Nginx](https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/).

Article dependencies:

- Django v4.2.3
- Docker v24.0.2
- Python v3.11.4

What I usually use:
Python 3.10.8 = 3.9.17
Django version 3.2.

I will stick with Python 3.10.11
Stick with the tutorial for now.

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

python3.11 -m venv env

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

For Windows 11 with bash in VSCode:
source env/Scripts/activate

app\docker-compose.yml

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
