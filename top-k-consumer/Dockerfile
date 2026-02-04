# Use the official Flink base image
FROM flink:1.17.1-scala_2.12

# Set the Flink opt directory as the working directory
WORKDIR /opt/flink/opt

# Copy the Flink job JAR into the image
# This assumes the shadowJar task will produce a JAR named flink-job-1.0-SNAPSHOT.jar
COPY build/libs/flink-job-1.0-SNAPSHOT.jar flink-job-1.0-SNAPSHOT.jar
