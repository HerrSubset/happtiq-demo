setup:
    gcloud auth configure-docker europe-west3-docker.pkg.dev

run:
    docker build --tag happtiq-demo:local .
    docker run -p 8080:80 happtiq-demo:local

deploy:
    docker build --tag europe-west3-docker.pkg.dev/happtiq-pjsmets-demo-play/happtiq-demo/happtiq-demo:latest .
    docker push europe-west3-docker.pkg.dev/happtiq-pjsmets-demo-play/happtiq-demo/happtiq-demo:latest

