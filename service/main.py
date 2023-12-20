import os
import sys

import uvicorn
from fastapi import FastAPI
from meta import ProjectMeta

sys.path.append(os.path.join(os.path.dirname(__file__), ".."))  # noqa

from config import Config, get_config  # noqa

config: Config = get_config()


def get_app() -> FastAPI:
    """Initializes and returns a FastAPI object"""
    project_meta: ProjectMeta = ProjectMeta()
    api: FastAPI = FastAPI(
        debug=config.app.debug,
        swagger_ui_parameters={"persistAuthorization": True},
        title=project_meta.title,
        description=project_meta.description,
        version=project_meta.version,
        **{"docs_url": None, "redoc_url": None} if not config.app.debug else {}
    )
    return api


app: FastAPI = get_app()


@app.get("/")
def root() -> dict[str, str]:
    return {"status": "Ok"}


if __name__ == "__main__":
    uvicorn.run(app, host=str(config.app.host), port=int(config.app.port))
