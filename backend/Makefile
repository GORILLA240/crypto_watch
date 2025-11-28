.PHONY: help install test lint format clean build deploy-dev deploy-staging deploy-prod local

help:
	@echo "Available commands:"
	@echo "  make install        - Install dependencies"
	@echo "  make test          - Run all tests"
	@echo "  make test-unit     - Run unit tests only"
	@echo "  make test-property - Run property-based tests only"
	@echo "  make lint          - Run linters"
	@echo "  make format        - Format code with black"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make build         - Build SAM application"
	@echo "  make deploy-dev    - Deploy to development"
	@echo "  make deploy-staging - Deploy to staging"
	@echo "  make deploy-prod   - Deploy to production"
	@echo "  make local         - Run API locally"

install:
	pip install -r requirements-dev.txt

test:
	pytest tests/ -v --cov=src --cov-report=html

test-unit:
	pytest tests/unit/ -v -m "not property"

test-property:
	pytest tests/unit/ -v -m property

test-integration:
	pytest tests/integration/ -v

lint:
	flake8 src/ tests/
	mypy src/

format:
	black src/ tests/

clean:
	rm -rf .aws-sam/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf .coverage
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

build:
	sam build

validate:
	sam validate --lint

deploy-dev: build
	sam deploy --config-env dev

deploy-staging: build
	sam deploy --config-env staging

deploy-prod: build
	sam deploy --config-env prod

local:
	sam local start-api --warm-containers EAGER

invoke-api:
	sam local invoke ApiFunction --event events/api-event.json

invoke-update:
	sam local invoke PriceUpdateFunction --event events/update-event.json
