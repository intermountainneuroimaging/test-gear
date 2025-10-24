"""Main module."""

import logging
import subprocess as sp
import os
import shutil

log = logging.getLogger(__name__)


def main_execute(gear_options, path):
    """[summary].

    Returns:
        [type]: [description]
    """
    log.info("This is the beginning of the run file")

    # duplicate input data to the output folder, zip
    source_dir = path
    destination_dir = os.path.join(gear_options["work-dir"], gear_options["destination-id"])

    try:
        shutil.copytree(source_dir, destination_dir)
        print(f"Directory '{source_dir}' copied successfully to '{destination_dir}'.")
    except FileExistsError:
        print(f"Destination directory '{destination_dir}' already exists. Please remove it or choose a different name.")
    except Exception as e:
        print(f"An error occurred: {e}")

    # zip outputs
    cmd = f'zip -r {gear_options["output-dir"]}/output_{gear_options["destination-id"]}.zip {gear_options["destination-id"]}'
    execute_shell(cmd, cwd=gear_options["work-dir"])


    log.info(f'Zipping path: {path}')

    return 0


def execute_shell(cmd, dryrun=False, cwd=os.getcwd()):
    log.info("\n %s", cmd)
    if not dryrun:
        terminal = sp.Popen(
            cmd,
            shell=True,
            stdout=sp.PIPE,
            stderr=sp.PIPE,
            universal_newlines=True,
            cwd=cwd
        )
        stdout, stderr = terminal.communicate()
        returnCode = terminal.poll()
        log.debug("\n %s", stdout)
        log.debug("\n %s", stderr)

        if stderr:
            log.warning("Error. \n%s\n%s", stdout, stderr)
            returnCode = 1
        return returnCode