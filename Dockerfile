FROM python:3.8.0

WORKDIR /user/src/app


COPY './app' .

RUN pip install -r ./app/requirements.txt

ENTRYPOINT [ "python", "./app/simple-app.py" ]