#FROM ubuntu:19.04
FROM ubuntu:18.04

ARG username=user
ENV configured_user=$username

# get current package list and update
RUN apt-get update && apt-get upgrade -y
# install base/nice-to-have packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata less mc aptitude bash-completion lsb-release locales software-properties-common # dialog
# install python and jupyter deps (& hack to fix CNTK deps)
RUN apt-get install -y python3 python3-pip openmpi-bin curl && \
  ln -s /usr/lib/x86_64-linux-gnu/libmpi_cxx.so.20 /usr/lib/x86_64-linux-gnu/libmpi_cxx.so.1 && \
  ln -s /usr/lib/x86_64-linux-gnu/libmpi.so.20.10.1 /usr/lib/x86_64-linux-gnu/libmpi.so.12


# deps for installing the jupyter R kernel
RUN apt-get install -y libzmq3-dev libcurl4-openssl-dev libssl-dev

# install R
COPY rstudio.list /etc/apt/sources.list.d/
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
RUN apt-get update
RUN apt-get install -y r-base
RUN chown -R 1000 /usr/local/lib

# for permissions: create default user with UID 1000
RUN useradd -u 1000 -d /home/$username -m -o $username

WORKDIR /home/$username
USER 1000

# update and install basic python packages
RUN pip3 install --upgrade --user pip
RUN . ~/.profile && pip install --upgrade --user \
  jupyter scipy==1.2.1 singledispatch matplotlib Image scikit-image pandas==0.23.4 setuptools \
  dill pyfunctional

# install the R kernel
COPY r-kernel.R /tmp/
RUN . ~/.profile && Rscript /tmp/r-kernel.R 

# install ML and related packages
RUN . ~/.profile && pip install --upgrade --user \
  nltk requests keras azure sklearn sklearn.utils tensorflow seaborn statsmodels cntk
RUN . ~/.profile && pip install --upgrade --user \
  cognitive_face azure-cognitiveservices-vision-customvision azureml.core \
  azureml.train azureml.train.automl azureml.widgets

#RUN . ~/.profile && pip install --upgrade --user \
#  aiohttp botbuilder-ai botbuilder-applicationinsights botbuilder-azure \
#  botbuilder-core botbuilder-dialogs botbuilder-schema botframework-connector

COPY jupyter_notebook_config.py /home/$username/.jupyter/jupyter_notebook_config.py

EXPOSE 8889
VOLUME /data
WORKDIR /data

#ENTRYPOINT ["/home/$configured_user/.local/bin/jupyter"]
ENTRYPOINT /home/"$configured_user"/.local/bin/jupyter notebook --ip=0.0.0.0 --port=8889
#CMD ["--port=8889"]
