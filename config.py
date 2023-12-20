from functools import lru_cache
from pathlib import Path

from pydantic import BaseModel, DirectoryPath, Field, IPvAnyAddress
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR: Path = Path().absolute()


class InstallerConfig(BaseModel):
    arg_fields: frozenset[str] = Field(frozenset(("service_name",)), exclude=True)

    templates_dir: str = "system_templates/"
    service_template_name: str = "sh_runner_app.j2"
    sys_daemon_dir: DirectoryPath = "/etc/systemd/system"
    venv_dir: DirectoryPath = str(BASE_DIR / ".venv")
    service_name: str = "sh_runner_app.service"


class ProjectConfig(BaseModel):
    base_dir: DirectoryPath = str(BASE_DIR)
    service_dir: DirectoryPath = str(BASE_DIR / "service")


class AppConfig(BaseModel):
    arg_fields: frozenset[str] = Field(
        frozenset(
            (
                "debug",
                "host",
                "port",
            )
        ),
        exclude=True,
    )

    debug: bool = True
    host: IPvAnyAddress = "127.0.0.1"
    port: str = "8888"


class Config(BaseSettings):
    model_config = SettingsConfigDict(
        extra="allow", env_file=".env", env_file_encoding="utf-8", env_prefix="", env_nested_delimiter="__"
    )

    project: ProjectConfig = ProjectConfig()
    installer: InstallerConfig = InstallerConfig()
    app: AppConfig = AppConfig()


@lru_cache()
def get_config() -> Config:
    return Config()
