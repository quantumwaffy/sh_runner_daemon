import argparse
from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, Template

from config import Config, get_config

config: Config = get_config()


class Installer:
    _arg_key_prefix: str = "--"

    def __init__(self) -> None:
        self._environment: Environment = Environment(loader=FileSystemLoader(config.installer.templates_dir))
        self._service_template: Template = self._environment.get_template(config.installer.service_template_name)
        self._arg_parser: argparse.ArgumentParser = self._get_argument_parser()

    def _get_argument_parser(self) -> argparse.ArgumentParser:
        arg_parser: argparse.ArgumentParser = argparse.ArgumentParser(description="Service installer")
        delimiter: str = config.model_config.get("env_nested_delimiter")
        for name, conf in config.model_fields.items():
            default_data: dict[str, Any] = conf.default.__dict__.copy()
            arg_fields: frozenset[str] | None = default_data.pop("arg_fields", None)
            if not arg_fields:
                continue
            for field_name, default_value in default_data.items():
                if field_name not in arg_fields:
                    continue
                env_var_name: str = f"{name}{delimiter}{field_name}"
                arg_parser.add_argument(
                    f"{self._arg_key_prefix}{env_var_name}",
                    dest=env_var_name,
                    help=f"'{env_var_name.upper()}' ENV VARIABLE",
                    default=default_value,
                )
        return arg_parser

    @staticmethod
    def _set_env_vars(args: argparse.Namespace) -> None:
        delimiter: str = config.model_config.get("env_nested_delimiter")
        with open(Path(config.project.base_dir) / ".env", "w") as env_f:
            for name, conf in config.model_fields.items():
                default_data: dict[str, Any] = conf.default.__dict__.copy()
                for field_name, default_value in default_data.items():
                    env_field_name: str = f"{name}{delimiter}{field_name}"
                    if (set_var := args.__dict__.get(env_field_name)) and set_var != default_value:
                        env_f.write(f"{env_field_name}={set_var}")

    def execute(self) -> None:
        args: argparse.Namespace = self._arg_parser.parse_args()
        self._set_env_vars(args)
        content: str = self._service_template.render(
            working_dir=config.project.service_dir,
            venv_dir=config.installer.venv_dir,
        )
        with open(Path(config.installer.sys_daemon_dir) / args.installer__service_name, "w", encoding="utf-8") as f:
            f.write(content)


if __name__ == "__main__":
    Installer().execute()
