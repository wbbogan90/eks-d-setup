IMAGE_NAME=eks_builder

build-u:
	docker build -t ${IMAGE_NAME} -f Dockerfile-U .

# Unclassified environment: Mounts the user's home/.aws directory to the ec2-user within the container
run-u: build-u
	docker run -it --mount type=bind,source=${HOME}/.aws,target=/home/ec2-user/.aws ${IMAGE_NAME} 2>/dev/null ; true

prune:
	docker system prune -a