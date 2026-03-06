FROM alpine:3.22.0

# Install dependencies
RUN apk add --no-cache \
    python3>=3.10 \
    py3-pip \
    build-base \
    python3-dev \
    libffi-dev \
    git

# Create and activate a virtual environment
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Upgrade pip and setuptools within the virtual environment
RUN pip3 install --no-cache --upgrade pip setuptools

# Install Python packages
RUN pip3 install --ignore-requires-python Qualys-IaC-Security

# Copy application files
COPY entrypoint.sh /entrypoint.sh
COPY resultParser.py /resultParser.py

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

# Set the container entrypoint
ENTRYPOINT ["sh", "/entrypoint.sh"]
