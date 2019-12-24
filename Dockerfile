FROM ubuntu:16.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    locales \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    mecab \
    libmecab-dev \
    mecab-ipadic-utf8 \
    build-essential \
    libssl-dev \
    libffi-dev \
    python-dev \
 && locale-gen ja_JP.UTF-8 \
 && echo "export LANG=ja_JP.UTF-8" >> ~/.bashrc \
 && rm -rf /var/lib/apt/lists/*

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda
RUN curl -so ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh
ENV PATH=/home/user/miniconda/bin:$PATH
ENV CONDA_AUTO_UPDATE_CONDA=false

# Create a Python 3.6 environment
RUN /home/user/miniconda/bin/conda create -y --name py36 python=3.6.9 \
 && /home/user/miniconda/bin/conda clean -ya
ENV CONDA_DEFAULT_ENV=py36
ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
ENV PATH=$CONDA_PREFIX/bin:$PATH
RUN /home/user/miniconda/bin/conda install conda-build=3.18.9=py36_3 \
 && /home/user/miniconda/bin/conda clean -ya

# No CUDA-specific steps
ENV NO_CUDA=1
RUN conda install -y -c pytorch \
    cpuonly \
    "pytorch=1.2.0=py3.6_cpu_0" \
    "torchvision=0.4.0=py36_cpu" \
 && conda clean -ya

WORKDIR /usr/app

COPY ./requirements.txt ./
RUN pip install -r requirements.txt

COPY ./app /usr/app
ADD ./app/models /usr/app/models
EXPOSE 8080

# Load Pretrained model for transformers
RUN python -c "from transformers.modeling_bert import BertModel; BertModel.from_pretrained('bert-base-japanese')"
RUN python -c "from transformers.tokenization_bert_japanese import BertJapaneseTokenizer; BertJapaneseTokenizer.from_pretrained('bert-base-japanese')"

# Set the default command to python3
ENTRYPOINT ["python3"]
CMD ["app.py"]