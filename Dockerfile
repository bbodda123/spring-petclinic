# The builder image is based on Eclipse Temurin JDK 17 with Maven
FROM maven:3.9.16-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml mvnw mvnw.cmd ./
COPY .mvn .mvn

# Download dependencies (cached)
RUN ./mvnw dependency:go-offline

COPY . . 
# Build the application
RUN ./mvnw clean package -DskipTests


# The runner image is based on Eclipse Temurin JDK 17 Alpine
FROM eclipse-temurin:17-jre-alpine AS runner

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

# Copy the jar to the production image from the builder stage. and change ownership to the spring user
COPY --from=builder --chown=spring:spring /app/target/spring-petclinic-4.0.0-SNAPSHOT.jar app.jar

RUN apk add --no-cache curl

USER spring

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]