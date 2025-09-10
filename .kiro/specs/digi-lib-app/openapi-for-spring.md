# OpenAPI for Spring Boot Generation — Digital Library App

This document shows how to generate a Java + Spring Boot server from the OpenAPI YAML and contains useful notes.

## Files in workspace
- OpenAPI YAML: `.kiro/specs/digi-lib-app/digi-lib-openapi.yaml`
- Postgres schema SQL: `.kiro/specs/digi-lib-app/digi-lib-postgres-schema.sql`

## Generate Spring Boot server using OpenAPI Generator (CLI)
1. Install OpenAPI Generator CLI: `brew install openapi-generator` or download jar.
2. Generate:
```bash
openapi-generator-cli generate -i .kiro/specs/digi-lib-app/digi-lib-openapi.yaml -g spring -o generated-springboot \
  --additional-properties=useSpringBoot3=true,interfaceOnly=false,delegatePattern=true,packageName=com.digitallibrary.api
```
3. Post-generation: add dependencies, implement delegates/controllers, security, and wire DB.

## Post-generation tasks
- Add dependencies:
  - `spring-boot-starter-web`
  - `spring-boot-starter-security`
  - `spring-boot-starter-data-jpa`
  - `postgresql`
  - `flyway-core` or `liquibase-core`
- Provide implementation for interfaces (delegates/controllers) generated.
- Implement JWT filter and authentication provider that validates tokens issued by your OAuth backend.
- Wire database config and apply the SQL migration file.

