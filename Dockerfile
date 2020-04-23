# Use our python alpine image to run webapp proper
FROM uisautomation/python:3.7-alpine

# Ensure packages are up to date and install some useful utilities
RUN apk update && apk add git vim postgresql-dev libffi-dev gcc musl-dev \
	libxml2-dev libxslt-dev libjpeg-turbo-dev

# From now on, work in the application directory
WORKDIR /usr/src/app

# Copy Docker configuration and install any requirements.
ADD ./requirements-fixed.txt ./
RUN pip install --no-cache-dir -r requirements-fixed.txt

# Default environment for image.  By default, we use the settings module bundled
# with this repo. Change DJANGO_SETTINGS_MODULE to install a custom settings.
#
# You probably want to modify the following environment variables:
#
# DJANGO_DB_ENGINE, DJANGO_DB_HOST, DJANGO_DB_PORT, DJANGO_DB_USER
EXPOSE 8080
ENV \
	DJANGO_SETTINGS_MODULE=botolphs.settings \
	PORT=8080

# Copy remaining application files
COPY ./manage.py ./
COPY ./botolphs/ ./botolphs/

# Collect static files using placeholder values for required settings.
RUN DJANGO_SECRET_KEY=placeholder ./manage.py collectstatic

# Create unprivileged user to run application
RUN adduser -S webapp

# Give webapp ability to *read* files but not write anything. Our container
# should not need to write to the local filesystem.
RUN chown -R webapp /usr/src/app && chmod -R oug-w /usr/src/app

# Run everything as the unprivileged user
USER webapp

# Use gunicorn as a web-server after running migration command
CMD gunicorn \
	--name botolphs \
	--bind :$PORT \
	--workers 3 \
	--log-level=info \
	--log-file=- \
	--access-logfile=- \
	--capture-output \
	botolphs.wsgi
