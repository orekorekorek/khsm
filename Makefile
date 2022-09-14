%:
	@:

test_alias=test t
test:
	docker-compose run --rm app bundle exec rspec $(filter-out $(test_alias), $(MAKECMDGOALS))

console:
	docker-compose run --rm app bundle exec rails c

bash:
	docker-compose run --rm app bash

attach:
	docker attach khsm60-app-1

restart:
	docker restart khsm60-app-1

start:
	docker-compose up 
