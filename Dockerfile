FROM liquibase/liquibase:4.27

WORKDIR /liquibase

# Copy migration files
COPY sql/ /liquibase/changelog/
COPY liquibase.properties /liquibase/

# Default command: show help
CMD ["--help"]
