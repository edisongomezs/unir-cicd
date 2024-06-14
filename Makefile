.PHONY: all $(MAKECMDGOALS)

build:
	docker build -t calculator-app .
	docker build -t calc-web ./web

server:
	docker run --rm --name apiserver --network-alias apiserver --env PYTHONPATH=/opt/calc --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0

test-unit:
	docker run --name unit-tests --env PYTHONPATH=/opt/calc -w /opt/calc calculator-app:latest pytest --cov --cov-report=xml:results/coverage.xml --cov-report=html:results/coverage --junit-xml=results/unit_result.xml -m unit || exit 0
	docker cp unit-tests:/opt/calc/results ./
	docker rm unit-tests || exit 0

test-api:
	@if docker network inspect calc-test-api >nul 2>&1; then docker network rm calc-test-api; fi
	docker network create calc-test-api
	-@docker stop apiserver || exit 0
	-@docker rm --force apiserver || exit 0
	docker run -d --network calc-test-api --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run --network calc-test-api --name api-tests --env PYTHONPATH=/opt/calc --env BASE_URL=http://apiserver:5000/ -w /opt/calc calculator-app:latest pytest --junit-xml=results/api_result.xml -m api || exit 0
	docker cp api-tests:/opt/calc/results ./
	docker stop apiserver || exit 0
	docker rm --force apiserver || exit 0
	docker stop api-tests || exit 0
	docker rm --force api-tests || exit 0
	docker network rm calc-test-api || exit 0

test-e2e:
	@if docker network inspect calc-test-e2e >nul 2>&1; then docker network rm calc-test-e2e; fi
	docker network create calc-test-e2e
	-@docker stop apiserver || exit 0
	-@docker rm --force apiserver || exit 0
	-@docker stop calc-web || exit 0
	-@docker rm --force calc-web || exit 0
	-@docker stop e2e-tests || exit 0
	-@docker rm --force e2e-tests || exit 0
	docker run -d --network calc-test-e2e --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc calculator-app:latest flask run --host=0.0.0.0
	docker run -d --network calc-test-e2e --name calc-web -p 80:80 calc-web
	docker create --network calc-test-e2e --name e2e-tests cypress/included:4.9.0 --browser chrome || exit 0
	docker cp ./test/e2e/cypress.json e2e-tests:/cypress.json
	docker cp ./test/e2e/cypress e2e-tests:/cypress
	docker start -a e2e-tests || exit 0
	docker cp e2e-tests:/results ./ || exit 0
	docker rm --force apiserver || exit 0
	docker rm --force calc-web || exit 0
	docker rm --force e2e-tests || exit 0
	docker network rm calc-test-e2e || exit 0
