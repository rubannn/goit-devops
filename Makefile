.PHONY: run stop clean status

run:
	docker compose up -d --build --wait

stop:
	docker compose stop

status:
	docker compose ps --all

clean:
	docker compose down --rmi all --remove-orphans
