---
short-title: 4. Using services-flake
---

# Integrating external services using services-flake

>[!warning] TODO: Write this! 
> For now, see the code: https://github.com/juspay/todo-app/pull/22

Things to highlight:

- `services-flake` provides pre-defined configurations for many services, reducing a bunch of lines to just `services.<service>.<instance>.enable = true;`
- Data directory for all services in `services-flake` is local to the project working directory, by default
- Best practices:
  - Use Unix sockets for local development and CI to avoid binding to ports (which is global to the interface)
  - Write integration tests using the reserved `test` process in `process-compose-flake`.
