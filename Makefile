IMAGE_NAME=eks_builder

build:
	cp ~/.aws/credentials .
	docker build -t ${IMAGE_NAME} .
	rm credentials

run:
	docker run -it ${IMAGE_NAME} 2> /dev/null

prune:
	docker system prune -a