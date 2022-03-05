FROM joelogan/keras-tensorflow-flask-uwsgi-nginx-docker
COPY ./requirements.txt /var/www/requirements.txt
RUN python3 -m pip install --upgrade pip
RUN pip install -r /var/www/requirements.txt