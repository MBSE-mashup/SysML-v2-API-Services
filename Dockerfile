FROM sbtscala/scala-sbt:graalvm-ce-22.3.3-b1-java11_1.9.8_3.3.1

# found Dockerfile at https://github.com/Systems-Modeling/SysML-v2-API-Services/issues/115
# according to docker hub docu of sbtscala/scala-sbt the images are tagged according to
# versions like: <JDK version>_<sbt version>_<Scala version>

WORKDIR /app
COPY ./ /app
RUN sbt -v clean compile
# RUN sbt -v evicted
EXPOSE  9000
CMD ["sbt", "-v", "run"]
