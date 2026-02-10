# Use the official Flink 1.17 image as a base
FROM flink:2.2.0

# Copy the fat JAR produced by the shadowJar task into Flink's user library directory.
# Flink automatically adds JARs from this directory to its classpath.
COPY build/libs/flink-job-1.0-SNAPSHOT.jar /opt/flink/usrlib/