import logging.config


def get_logger(name: str) -> logging.Logger:
    """Function that returns the logger to a specific module"""
    logging.config.fileConfig("logging.conf", disable_existing_loggers=False)
    return logging.getLogger(name)
