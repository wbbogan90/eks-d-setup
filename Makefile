IMAGE_NAME=eks_builder

build:
	docker build -t ${IMAGE_NAME} .

# Unclassified environment: Mounts the user's home/.aws directory to the EKS user within the container
run-u:
	docker run -it --mount type=bind,source=${HOME}/.aws,target=/home/eks/.aws ${IMAGE_NAME} 2>/dev/null ; true

prune:
	docker system prune -a