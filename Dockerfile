# RESTForms2 development Docker image
ARG IMAGE=store/intersystems/iris-community:2019.3.0.309.0
ARG IMAGE=store/intersystems/iris-community:2019.4.0.379.0
FROM $IMAGE

USER root
RUN mkdir -p /opt/restforms2
RUN mkdir -p /opt/restforms2/src
RUN mkdir -p /opt/restforms2/db
COPY irissession.sh /
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /irissession.sh
RUN chmod u+x /irissession.sh
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/restforms2
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/restforms2/src
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/restforms2/db

WORKDIR /opt/restforms2

USER irisowner
COPY src src
SHELL ["/irissession.sh"]

# run installer
RUN \
  do $SYSTEM.OBJ.Load("/opt/restforms2/src/Form/Installer.cls", "ck") \
  set sc = ##class(Form.Installer).Run() 

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]