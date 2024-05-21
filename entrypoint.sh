#!/bin/sh

if [ "$DATABASE" = "postgres" ]
then
    echo "Waiting for postgres..."

    # Check network connectivity to the PostgreSQL host and port
    while ! timeout 1 bash -c "echo > /dev/tcp/$SQL_HOST/$SQL_PORT"; do
      sleep 0.1
    done

    echo "PostgreSQL started"
fi

python manage.py flush --no-input
python manage.py migrate

exec "$@"