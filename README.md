# irasutoya generator

## How to start app

first, download pretrained model [here](https://drive.google.com/open?id=1V8U-3rixzbOA-YXaPgpABjkDmJew0tzR) and locate it to `app/models/`.

next, create docker image (image size is ~3GB).

```bash
docker build -t <name>/<image-name> .
```

and run docker container on port forwarding by internal port 8080 toward exposing external port you like.

```bash
docker container run -p 8080:8080 <name>/<image-name>
```

