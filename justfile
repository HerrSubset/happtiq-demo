run:
    docker build --tag happtiq-demo:local .
    docker run -p 8080:80 happtiq-demo:local
