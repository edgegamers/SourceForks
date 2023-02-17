FROM alpine AS sourcemod_huge

RUN wget -c https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6931-linux.tar.gz -O - | tar -xz

FROM bitnami/minideb:bullseye as sourcemod

COPY scripting scripting
COPY --from=sourcemod_huge addons/sourcemod/scripting scripting

WORKDIR scripting

ENV PATH = /scripting:$PATH
ENV SPCOMPOPTS = ""

ENTRYPOINT [ "./spcomp64" ]