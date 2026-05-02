FROM nvidia/cuda:12.6.0-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::ftp::Timeout "30";' >> /etc/apt/apt.conf.d/80-retries

RUN apt-get update --fix-missing && \
    apt-get install -y --fix-missing --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libreoffice \
    default-jre \
    poppler-utils \
    git \
    curl \
    ca-certificates \
    libgl1 \
    libglib2.0-0t64 \
    libgomp1 \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ln -s /usr/bin/python3 /usr/bin/python
RUN python -c "import pkg_resources; print('pkg_resources available')"

WORKDIR /app

COPY requirements.txt requirements_original.txt
RUN cat requirements_original.txt | \
    grep -v "^pandas==" | \
    grep -v "^pandasai" | \
    grep -v "^memray" | \
    grep -v "^milvus-lite" | \
    grep -v "^triton" | \
    grep -v "^xformers" > requirements_modified.txt && \
    echo "pandas" >> requirements_modified.txt

RUN pip3 install --no-cache-dir --break-system-packages -r requirements_modified.txt

COPY . .

RUN mkdir -p /data

RUN echo '#!/bin/bash\necho "QWEN_API_KEY=$QWEN_API_KEY" > /app/.env\necho "DASHSCOPE_API_KEY=$DASHSCOPE_API_KEY" >> /app/.env\ncd /app\nexport PYTHONPATH=/app:$PYTHONPATH\nexec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "-m", "PosterAgent.new_pipeline", "--help"]
