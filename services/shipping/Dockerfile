FROM mirror.gcr.io/python:3.13-alpine
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 3004
ENTRYPOINT ["python"]
CMD ["app.py"]