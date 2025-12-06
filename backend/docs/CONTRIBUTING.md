# Contributing to Crypto Watch Backend

## Testing Policy

### Test Requirements

All code contributions must include appropriate tests. A feature is not considered complete until tests are written and passing.

### Test Types

1. **Unit Tests**: Test individual functions and classes
2. **Property-Based Tests**: Test universal properties across many inputs
3. **Integration Tests**: Test component interactions

### Test Creation Order

```
1. Implement feature/fix
2. Write unit tests for specific logic and edge cases
3. Write property-based tests for correctness properties
4. Run tests locally and fix any failures
5. Write integration tests (if applicable)
6. Commit and push
```

### Coverage Goals

- **Minimum**: 80% code coverage
- **Target**: 90% code coverage
- **Critical paths**: 100% coverage

### Test Naming Conventions

#### Unit Tests
```python
def test_<function_name>_<scenario>():
    """Test that <function> <expected behavior> when <condition>."""
```

Example:
```python
def test_validate_api_key_rejects_invalid_key():
    """Test that validate_api_key raises error when key is invalid."""
```

#### Property-Based Tests
```python
def test_property_<number>_<description>():
    """
    Property <number>: <property description>
    Validates: Requirements <requirement numbers>
    """
```

Example:
```python
def test_property_2_cache_freshness_determines_data_source():
    """
    Property 2: Cache freshness determines data source
    Validates: Requirements 2.1
    """
```

#### Integration Tests
```python
def test_integration_<flow_name>():
    """Test <end-to-end flow description>."""
```

### Running Tests

```bash
# Run all tests
pytest

# Run specific test type
pytest tests/unit/ -v
pytest tests/unit/ -v -m property
pytest tests/integration/ -v -m integration

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/test_api.py -v

# Run specific test
pytest tests/unit/test_api.py::test_validate_api_key_rejects_invalid_key -v
```

### Test Failure Policy

- **Never commit failing tests**
- **Fix tests before moving to next task**
- **Don't skip tests to make CI pass**
- **Don't mock away real functionality**

### Property-Based Testing Guidelines

1. **Use Hypothesis** for property-based tests
2. **Run minimum 100 iterations** per property
3. **Tag with design document reference**:
   ```python
   # Feature: crypto-watch-backend, Property 2: Cache freshness
   @given(st.datetimes())
   def test_cache_freshness(timestamp):
       ...
   ```
4. **Test real properties**, not implementation details
5. **Use smart generators** that constrain to valid input space

## Code Quality Standards

### Linting

```bash
# Run flake8
flake8 src/ tests/

# Run black (auto-format)
black src/ tests/

# Run mypy (type checking)
mypy src/ --ignore-missing-imports
```

### Code Style

- Follow PEP 8
- Use type hints
- Write docstrings for public functions
- Keep functions small and focused
- Avoid deep nesting

### Example

```python
def calculate_cache_age(last_updated: datetime) -> float:
    """
    Calculate the age of cached data in seconds.
    
    Args:
        last_updated: Timestamp when data was last updated
        
    Returns:
        Age of the data in seconds
        
    Raises:
        ValueError: If last_updated is in the future
    """
    if last_updated > datetime.now(timezone.utc):
        raise ValueError("last_updated cannot be in the future")
    
    time_diff = datetime.now(timezone.utc) - last_updated
    return time_diff.total_seconds()
```

## Pull Request Process

### Before Creating PR

- [ ] All tests passing locally
- [ ] Code coverage meets minimum (80%)
- [ ] Linting passes (flake8, black)
- [ ] Type checking passes (mypy)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Property tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests passing

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests provide good coverage

## Related Issues
Closes #123
```

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **Code review** by at least one team member
3. **Testing verification** in staging
4. **Approval** from code owner
5. **Merge** to main branch

## Task Completion Checklist

Use this checklist for each task:

```markdown
## Task: [Task Name]

### Implementation
- [ ] Core functionality implemented
- [ ] Error handling added
- [ ] Logging added
- [ ] Documentation updated

### Testing
- [ ] Unit tests written
- [ ] Property tests written (if applicable)
- [ ] Integration tests written (if applicable)
- [ ] All tests passing
- [ ] Coverage > 80%

### Code Quality
- [ ] Linting passed
- [ ] Type checking passed
- [ ] Code reviewed
- [ ] No security issues

### Documentation
- [ ] Code comments added
- [ ] Docstrings written
- [ ] README updated (if needed)
- [ ] CHANGELOG updated

### Verification
- [ ] Tested locally
- [ ] Tested in dev environment
- [ ] No regressions
- [ ] Performance acceptable

### Completion
- [ ] PR created
- [ ] PR approved
- [ ] Merged to main
- [ ] Deployed to staging
```

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/add-new-endpoint
```

### 2. Implement Feature

- Write code
- Add tests
- Update documentation

### 3. Test Locally

```bash
# Run tests
pytest

# Check coverage
pytest --cov=src --cov-report=term-missing

# Run linting
flake8 src/ tests/
black src/ tests/
mypy src/
```

### 4. Commit Changes

```bash
git add .
git commit -m "feat: add new endpoint for cryptocurrency details"
```

Commit message format:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Tests
- `refactor:` Code refactoring
- `chore:` Maintenance

### 5. Push and Create PR

```bash
git push origin feature/add-new-endpoint
```

Then create PR on GitHub.

### 6. Address Review Comments

- Make requested changes
- Push updates
- Re-request review

### 7. Merge

After approval, squash and merge to main.

## Getting Help

- **Questions**: Ask in team Slack channel
- **Bugs**: Create GitHub issue
- **Documentation**: Check `/docs` folder
- **Code examples**: Look at existing tests

## Resources

- [Python Style Guide (PEP 8)](https://pep8.org/)
- [Pytest Documentation](https://docs.pytest.org/)
- [Hypothesis Documentation](https://hypothesis.readthedocs.io/)
- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
