# Keep the python at 3.9-slim to integrate well with
# the mriqc image.
FROM flywheel/python:3.12-debian AS fw_base
ENV FLYWHEEL="/flywheel/v0"
WORKDIR ${FLYWHEEL}

# Dev install. git for pip editable install.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean
RUN apt-get install --no-install-recommends -y \
    git \
    build-essential \
    zip \
    nodejs \
    tree \
    linux-libc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

######################################################
# FLYWHEEL GEAR STUFF...

# Add poetry oversight.
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
	 git \
     zip \
     unzip \
    curl \
    software-properties-common &&\
	apt-get update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Install poetry based on their preferred method. pip install is finnicky.
# Designate the install location, so that you can find it in Docker.
ENV PYTHONUNBUFFERED=1 \
    POETRY_VERSION=2.2.1 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # do not ask any interactive questions
    POETRY_NO_INTERACTION=1 \
    VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python -m pip install --upgrade pip && \
    ln -sf /usr/bin/python /opt/venv/bin/python3
ENV PATH="$POETRY_HOME/bin:$PATH"

# get-poetry respects ENV
RUN curl -sSL https://install.python-poetry.org | python3 - ;\
    ln -sf ${POETRY_HOME}/lib/poetry/_vendor/py3.9 ${POETRY_HOME}/lib/poetry/_vendor/py3.8; \
    chmod +x "$POETRY_HOME/bin/poetry"

# Installing main dependencies
ARG FLYWHEEL=/flywheel/v0
COPY pyproject.toml poetry.lock $FLYWHEEL/
WORKDIR $FLYWHEEL
RUN poetry install --no-root --no-dev

# add bc
RUN apt update &&\
    apt install -y --no-install-recommends bc

COPY run.py manifest.json $FLYWHEEL/
COPY fw_gear_fw_example $FLYWHEEL/fw_gear_fw_example
RUN poetry install --no-dev

# Configure entrypoint
RUN chmod a+x $FLYWHEEL/run.py
RUN chmod -R 755 /root
ENTRYPOINT ["poetry","run","python","/flywheel/v0/run.py"]
