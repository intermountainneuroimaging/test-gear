# Use an official Python base image
FROM python:3.12-slim

# Set environment variables for Poetry
ENV POETRY_HOME=/opt/poetry \
    PATH="/opt/poetry/bin:$PATH" \
    POETRY_VERSION=1.8.3

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

# Set working directory
WORKDIR /app

# poetry workaround
RUN pip install --upgrade pip setuptools wheel

# Copy your project definition files
# (Optional, do this only if you have a pyproject.toml + poetry.lock)
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root

# Default command (open shell)
CMD ["bash"]
