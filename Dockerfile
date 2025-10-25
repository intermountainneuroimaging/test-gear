# Use an official Python base image
FROM python:3.12-slim

# Set environment variables for Poetry
ENV POETRY_HOME=/opt/poetry \
    PATH="/opt/poetry/bin:$PATH" \
    POETRY_VERSION=1.8.3  \
    VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install system deps and Poetry
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        build-essential \
        git \
        zip \
        nodejs \
        tree \
        linux-libc-dev  \
        python3-dev \
    && curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} \
    && ln -s ${POETRY_HOME}/bin/poetry /usr/local/bin/poetry \
    && poetry --version \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# poetry workaround
RUN pip install --upgrade pip setuptools wheel

# Copy your project definition files
# (Optional, do this only if you have a pyproject.toml + poetry.lock)
ARG FLYWHEEL=/flywheel/v0
COPY pyproject.toml poetry.lock $FLYWHEEL/
WORKDIR $FLYWHEEL
RUN poetry install --no-root

# Default command (open shell)
CMD ["bash"]

# ENTRYPOINT ["poetry","run","python","/flywheel/v0/run.py"]
