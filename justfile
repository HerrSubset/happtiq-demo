setup:
    gcloud auth configure-docker europe-west3-docker.pkg.dev
    cd terraform/infrastructure && terraform init
    cd terraform/kubernetes_config && terraform init

tf-init-upgrade:
    cd terraform/infrastructure && terraform init -upgrade
    cd terraform/kubernetes_config && terraform init -upgrade

run:
    docker build --tag happtiq-demo:local .
    docker run -p 8080:80 happtiq-demo:local

deploy:
    docker build --tag europe-west3-docker.pkg.dev/happtiq-pjsmets-demo-play/happtiq-demo/happtiq-demo:latest .
    docker push europe-west3-docker.pkg.dev/happtiq-pjsmets-demo-play/happtiq-demo/happtiq-demo:latest
    cd terraform/infrastructure && terraform apply -auto-approve
    cd terraform/kubernetes_config && terraform apply -auto-approve

destroy:
    cd terraform/kubernetes_config && terraform destroy -auto-approve
    cd terraform/infrastructure && terraform destroy -auto-approve

